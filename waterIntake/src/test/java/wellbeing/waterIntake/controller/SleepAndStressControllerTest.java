package wellbeing.waterIntake.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import wellbeing.waterIntake.collections.SleepRecord;
import wellbeing.waterIntake.collections.StressRecord;
import wellbeing.waterIntake.repository.SleepRecordRepository;
import wellbeing.waterIntake.repository.StressRecordRepository;
import wellbeing.waterIntake.repository.UserRepository;

@WebMvcTest({SleepController.class, StressController.class})
@Import(SleepAndStressControllerTest.FixedClock.class)
class SleepAndStressControllerTest {

    @TestConfiguration
    static class FixedClock {
        @Bean
        @Primary
        Clock fixedClock() {
            return Clock.fixed(Instant.parse("2026-11-21T08:00:00Z"), ZoneOffset.UTC);
        }
    }

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private SleepRecordRepository sleepRecords;

    @MockitoBean
    private StressRecordRepository stressRecords;

    @MockitoBean
    private UserRepository users;

    @Test
    void logSleepComputesDurationAndUsesWakeUpDay() throws Exception {
        given(users.existsById("u1")).willReturn(true);
        given(sleepRecords.findByUserIdAndDate("u1", LocalDate.parse("2026-11-21"))).willReturn(Optional.empty());
        given(sleepRecords.save(any())).willAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/sleep/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","bedTime":"2026-11-20T23:15:00","wakeTime":"2026-11-21T07:00:00"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.date").value("2026-11-21"))
                .andExpect(jsonPath("$.durationMinutes").value(465));
    }

    @Test
    void logSleepAgainReplacesThatNight() throws Exception {
        SleepRecord existing = new SleepRecord("id1", "u1", LocalDate.parse("2026-11-21"),
                LocalDateTime.parse("2026-11-20T22:00"), LocalDateTime.parse("2026-11-21T06:00"), 480);
        given(users.existsById("u1")).willReturn(true);
        given(sleepRecords.findByUserIdAndDate("u1", LocalDate.parse("2026-11-21"))).willReturn(Optional.of(existing));
        given(sleepRecords.save(any())).willAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/sleep/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","bedTime":"2026-11-21T00:30:00","wakeTime":"2026-11-21T07:30:00"}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("id1"))
                .andExpect(jsonPath("$.durationMinutes").value(420));
    }

    @Test
    void logSleepRejectsWakeBeforeBed() throws Exception {
        mvc.perform(post("/sleep/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","bedTime":"2026-11-21T07:00:00","wakeTime":"2026-11-20T23:00:00"}"""))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.detail").value(org.hamcrest.Matchers.containsString("wakeTime")));
        verify(sleepRecords, never()).save(any());
    }

    @Test
    void logSleepRejectsFutureNight() throws Exception {
        mvc.perform(post("/sleep/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","bedTime":"2026-11-25T23:00:00","wakeTime":"2026-11-26T07:00:00"}"""))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getSleepReturnsRangeAndValidatesIt() throws Exception {
        given(sleepRecords.findInRange("u1", LocalDate.parse("2026-11-15"), LocalDate.parse("2026-11-21")))
                .willReturn(List.of(new SleepRecord("a", "u1", LocalDate.parse("2026-11-21"),
                        LocalDateTime.parse("2026-11-20T23:00"), LocalDateTime.parse("2026-11-21T07:00"), 480)));

        mvc.perform(get("/sleep/u1").param("from", "2026-11-15").param("to", "2026-11-21"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].durationMinutes").value(480));

        mvc.perform(get("/sleep/u1").param("from", "2026-11-21").param("to", "2026-11-15"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void logStressUpsertsAndTrimsNote() throws Exception {
        given(users.existsById("u1")).willReturn(true);
        given(stressRecords.findByUserIdAndDate("u1", LocalDate.parse("2026-11-21"))).willReturn(Optional.empty());
        given(stressRecords.save(any())).willAnswer(inv -> inv.getArgument(0));

        mvc.perform(post("/stress/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","date":"2026-11-21","level":4,"note":"  exams  "}"""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.level").value(4));

        ArgumentCaptor<StressRecord> saved = ArgumentCaptor.forClass(StressRecord.class);
        verify(stressRecords).save(saved.capture());
        assertThat(saved.getValue().getNote()).isEqualTo("exams");
    }

    @Test
    void logStressRejectsLevelOutOfRange() throws Exception {
        mvc.perform(post("/stress/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"u1","date":"2026-11-21","level":6}"""))
                .andExpect(status().isBadRequest());
        verify(stressRecords, never()).save(any());
    }

    @Test
    void logStressForUnknownUserIs404() throws Exception {
        given(users.existsById("ghost")).willReturn(false);
        mvc.perform(post("/stress/log").contentType(MediaType.APPLICATION_JSON).content("""
                        {"userId":"ghost","date":"2026-11-21","level":2}"""))
                .andExpect(status().isNotFound());
    }
}
