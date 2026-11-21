package wellbeing.waterIntake;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.mongodb.MongoDBContainer;

import wellbeing.waterIntake.repository.UserRepository;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** End-to-end test against a real MongoDB; skipped when Docker is not available. */
@SpringBootTest(properties = "app.demo-user.id=demo-user")
@AutoConfigureMockMvc
@Testcontainers(disabledWithoutDocker = true)
class WaterIntakeApplicationTests {

	@Container
	@ServiceConnection
	static MongoDBContainer mongo = new MongoDBContainer("mongo:8.0");

	@Autowired
	private MockMvc mvc;

	@Autowired
	private UserRepository users;

	@Test
	void demoUserIsCreatedAndIntakeIsSummedForToday() throws Exception {
		assertThat(users.findById("demo-user")).isPresent();

		mvc.perform(get("/users/demo-user/daily-goal"))
				.andExpect(status().isOk())
				.andExpect(content().string("2.5"));

		for (String amount : new String[] {"0.25", "0.5"}) {
			mvc.perform(post("/waterIntake/logIntake").contentType(MediaType.APPLICATION_JSON)
							.content("{\"userId\":\"demo-user\",\"amount\":" + amount + "}"))
					.andExpect(status().isOk());
		}

		mvc.perform(get("/waterIntake/daily/demo-user"))
				.andExpect(status().isOk())
				.andExpect(content().string("0.75"));
	}

	@Test
	void sleepAndStressAreStoredOncePerDayAndQueriedByRange() throws Exception {
		LocalDate today = LocalDate.now(ZoneOffset.UTC);
		String bed = today.minusDays(1) + "T23:00:00";
		for (String wake : new String[] {today + "T06:30:00", today + "T07:00:00"}) {
			mvc.perform(post("/sleep/log").contentType(MediaType.APPLICATION_JSON)
							.content("{\"userId\":\"demo-user\",\"bedTime\":\"" + bed + "\",\"wakeTime\":\"" + wake + "\"}"))
					.andExpect(status().isOk());
		}
		mvc.perform(post("/stress/log").contentType(MediaType.APPLICATION_JSON)
						.content("{\"userId\":\"demo-user\",\"date\":\"" + today.minusDays(2) + "\",\"level\":2}"))
				.andExpect(status().isOk());
		mvc.perform(post("/stress/log").contentType(MediaType.APPLICATION_JSON)
						.content("{\"userId\":\"demo-user\",\"date\":\"" + today.minusDays(10) + "\",\"level\":5}"))
				.andExpect(status().isOk());

		String from = today.minusDays(6).toString();
		String to = today.toString();
		mvc.perform(get("/sleep/demo-user").param("from", from).param("to", to))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].date").value(to))
				.andExpect(jsonPath("$[0].durationMinutes").value(480));
		mvc.perform(get("/stress/demo-user").param("from", from).param("to", to))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].level").value(2));
	}

}
