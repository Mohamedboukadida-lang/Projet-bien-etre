package wellbeing.waterIntake.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import wellbeing.waterIntake.collections.User;
import wellbeing.waterIntake.collections.WaterIntakeRecord;
import wellbeing.waterIntake.repository.UserRepository;
import wellbeing.waterIntake.repository.WaterIntakeRecordRepository;

@WebMvcTest(WaterIntakeController.class)
@Import(WaterIntakeControllerTest.FixedClock.class)
class WaterIntakeControllerTest {

    /** Wednesday 2026-11-18, 10:00 UTC. */
    static final Instant NOW = Instant.parse("2026-11-18T10:00:00Z");

    @TestConfiguration
    static class FixedClock {
        @Bean
        @Primary
        Clock fixedClock() {
            return Clock.fixed(NOW, ZoneOffset.UTC);
        }
    }

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private WaterIntakeRecordRepository records;

    @MockitoBean
    private UserRepository users;

    private static WaterIntakeRecord record(String isoDateTime, double amount) {
        return new WaterIntakeRecord(null, "u1", amount, LocalDateTime.parse(isoDateTime), null);
    }

    private static WaterIntakeRecord record(String isoDateTime, double amount, String localDate) {
        return new WaterIntakeRecord(null, "u1", amount, LocalDateTime.parse(isoDateTime), LocalDate.parse(localDate));
    }

    @Test
    void dailyIntakeDefaultsToTodayAndSumsRecords() throws Exception {
        given(records.findForLocalDays("u1", LocalDate.parse("2026-11-18"), LocalDate.parse("2026-11-18"),
                LocalDateTime.parse("2026-11-18T00:00"), LocalDateTime.parse("2026-11-19T00:00")))
                .willReturn(List.of(record("2026-11-18T08:00", 0.25), record("2026-11-18T09:00", 0.5)));

        mvc.perform(get("/waterIntake/daily/u1"))
                .andExpect(status().isOk())
                .andExpect(content().string("0.75"));
    }

    @Test
    void dailyIntakeUsesTheRequestedLocalDay() throws Exception {
        given(records.findForLocalDays("u1", LocalDate.parse("2026-11-19"), LocalDate.parse("2026-11-19"),
                LocalDateTime.parse("2026-11-19T00:00"), LocalDateTime.parse("2026-11-20T00:00")))
                .willReturn(List.of(record("2026-11-18T23:30", 0.5, "2026-11-19")));

        mvc.perform(get("/waterIntake/daily/u1").param("date", "2026-11-19"))
                .andExpect(status().isOk())
                .andExpect(content().string("0.5"));
        mvc.perform(get("/waterIntake/records/u1").param("date", "2026-11-19"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].date").value("2026-11-19"));
    }

    @Test
    void weeklySummaryContainsAllSevenDaysInOrder() throws Exception {
        given(records.findForLocalDays("u1", LocalDate.parse("2026-11-16"), LocalDate.parse("2026-11-22"),
                LocalDateTime.parse("2026-11-16T00:00"), LocalDateTime.parse("2026-11-23T00:00")))
                // A drink at 23:30 UTC on the 16th that the user logged on their local 17th counts for the 17th.
                .willReturn(List.of(record("2026-11-16T08:00", 1.0), record("2026-11-16T20:00", 0.5),
                        record("2026-11-16T23:30", 0.25, "2026-11-17"), record("2026-11-18T09:00", 2.0)));

        mvc.perform(get("/waterIntake/weeklySummary/u1"))
                .andExpect(status().isOk())
                .andExpect(content().json("""
                        {"2026-11-16":1.5,"2026-11-17":0.25,"2026-11-18":2.0,"2026-11-19":0.0,
                         "2026-11-20":0.0,"2026-11-21":0.0,"2026-11-22":0.0}"""));
    }

    @Test
    void logIntakeStoresRecordAtCurrentTime() throws Exception {
        given(users.existsById("u1")).willReturn(true);
        given(records.save(any())).willAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"u1\",\"amount\":0.25}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.amount").value(0.25))
                .andExpect(jsonPath("$.dateTime").value("2026-11-18T10:00:00"))
                .andExpect(jsonPath("$.date").value("2026-11-18"));
    }

    @Test
    void logIntakeStoresTheUsersLocalDate() throws Exception {
        given(users.existsById("u1")).willReturn(true);
        given(records.save(any())).willAnswer(inv -> inv.getArgument(0));

        // 10:00 UTC on the 18th is already the 19th for a user at UTC+14.
        mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"u1\",\"amount\":0.25,\"date\":\"2026-11-19\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dateTime").value("2026-11-18T10:00:00"))
                .andExpect(jsonPath("$.date").value("2026-11-19"));
    }

    @Test
    void logIntakeRejectsFutureDate() throws Exception {
        mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"u1\",\"amount\":0.25,\"date\":\"2026-11-25\"}"))
                .andExpect(status().isBadRequest());
        verify(records, never()).save(any());
    }

    @Test
    void logIntakeRejectsInvalidAmount() throws Exception {
        mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"u1\",\"amount\":-1}"))
                .andExpect(status().isBadRequest());
        verify(records, never()).save(any());
    }

    @Test
    void logIntakeForUnknownUserIs404() throws Exception {
        given(users.existsById("nobody")).willReturn(false);
        mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"userId\":\"nobody\",\"amount\":0.25}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void updateGoalSavesNewValue() throws Exception {
        User user = new User("u1", "demo", "d@example.com", 2.0);
        given(users.findById("u1")).willReturn(Optional.of(user));

        mvc.perform(post("/waterIntake/updateGoal/u1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"newGoal\":3.0}"))
                .andExpect(status().isOk());
        verify(users).save(eq(user));
        org.assertj.core.api.Assertions.assertThat(user.getDailyWaterIntakeGoal()).isEqualTo(3.0);
    }

    @Test
    void updateGoalRejectsMissingValue() throws Exception {
        mvc.perform(post("/waterIntake/updateGoal/u1").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
    }
}
