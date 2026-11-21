package wellbeing.waterIntake.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import wellbeing.waterIntake.collections.User;
import wellbeing.waterIntake.repository.UserRepository;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private UserRepository users;

    @Test
    void patchUpdatesOnlyTheGivenFields() throws Exception {
        User user = new User("u1", "Amira", "a@example.com", 2.5);
        user.setWeightKg(70.0);
        given(users.findById("u1")).willReturn(Optional.of(user));
        given(users.save(any())).willAnswer(inv -> inv.getArgument(0));

        mvc.perform(patch("/users/u1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"heightCm\":168,\"dateOfBirth\":\"1999-04-12\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.heightCm").value(168.0))
                .andExpect(jsonPath("$.weightKg").value(70.0))
                .andExpect(jsonPath("$.dateOfBirth").value("1999-04-12"))
                .andExpect(jsonPath("$.username").value("Amira"));

        assertThat(user.getHeightCm()).isEqualTo(168.0);
        assertThat(user.getWeightKg()).isEqualTo(70.0);
        assertThat(user.getDateOfBirth()).isEqualTo(LocalDate.of(1999, 4, 12));
    }

    @Test
    void patchRejectsImplausibleValues() throws Exception {
        for (String body : new String[] {
                "{\"heightCm\":20}", "{\"weightKg\":1000}", "{\"dateOfBirth\":\"2999-01-01\"}",
                "{\"dateOfBirth\":\"1850-01-01\"}"}) {
            mvc.perform(patch("/users/u1").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest());
        }
        verify(users, never()).save(any());
    }

    @Test
    void patchUnknownUserIs404() throws Exception {
        given(users.findById("ghost")).willReturn(Optional.empty());
        mvc.perform(patch("/users/ghost").contentType(MediaType.APPLICATION_JSON).content("{\"weightKg\":60}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void browsersMayPatch() throws Exception {
        mvc.perform(options("/users/u1")
                        .header("Origin", "http://localhost:5000")
                        .header("Access-Control-Request-Method", "PATCH"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Methods",
                        org.hamcrest.Matchers.containsString("PATCH")));
    }
}
