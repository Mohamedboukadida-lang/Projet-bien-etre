package wellbeing.waterIntake.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import wellbeing.waterIntake.collections.User;
import wellbeing.waterIntake.repository.UserRepository;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/add")
    public ResponseEntity<User> createUser(@RequestBody User user) {
        return ResponseEntity.ok(userRepository.save(user));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<User> getUser(@PathVariable String userId) {
        return ResponseEntity.of(userRepository.findById(userId));
    }

    @GetMapping("/{userId}/daily-goal")
    public ResponseEntity<Double> getDailyWaterIntakeGoal(@PathVariable String userId) {
        return userRepository.findById(userId)
                .map(user -> ResponseEntity.ok(user.getDailyWaterIntakeGoal()))
                .orElse(ResponseEntity.notFound().build());
    }
}
