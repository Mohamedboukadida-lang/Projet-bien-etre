package wellbeing.waterIntake;

import java.time.Clock;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class WaterIntakeApplication {

	public static void main(String[] args) {
		SpringApplication.run(WaterIntakeApplication.class, args);
	}

	/** Water intake days are computed in UTC. */
	@Bean
	Clock clock() {
		return Clock.systemUTC();
	}

}
