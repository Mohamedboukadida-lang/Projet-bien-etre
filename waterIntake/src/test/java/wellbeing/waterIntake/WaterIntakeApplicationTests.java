package wellbeing.waterIntake;

import static org.assertj.core.api.Assertions.assertThat;

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

}
