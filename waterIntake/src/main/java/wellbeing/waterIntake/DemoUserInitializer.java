package wellbeing.waterIntake;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import wellbeing.waterIntake.collections.User;
import wellbeing.waterIntake.repository.UserRepository;

/** Creates the demo user the mobile app uses, so a fresh database works out of the box. */
@Component
class DemoUserInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoUserInitializer.class);

    private final UserRepository userRepository;
    private final String demoUserId;
    private final double dailyGoal;

    DemoUserInitializer(UserRepository userRepository,
                        @Value("${app.demo-user.id:}") String demoUserId,
                        @Value("${app.demo-user.daily-goal:2.5}") double dailyGoal) {
        this.userRepository = userRepository;
        this.demoUserId = demoUserId;
        this.dailyGoal = dailyGoal;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (demoUserId.isBlank() || userRepository.existsById(demoUserId)) {
            return;
        }
        userRepository.save(new User(demoUserId, "demo", "demo@example.com", dailyGoal));
        log.info("Created demo user {} with a daily goal of {} L", demoUserId, dailyGoal);
    }
}
