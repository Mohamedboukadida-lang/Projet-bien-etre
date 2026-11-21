package wellbeing.waterIntake.controller;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import wellbeing.waterIntake.collections.User;
import wellbeing.waterIntake.collections.UserBodyDto;
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

    /** Updates height, weight and/or date of birth; fields left out of the body are not changed. */
    @PatchMapping("/{userId}")
    public ResponseEntity<User> updateBody(@PathVariable String userId, @Valid @RequestBody UserBodyDto body) {
        if (body.dateOfBirth() != null && body.dateOfBirth().getYear() < 1900) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "dateOfBirth must be in 1900 or later");
        }
        return userRepository.findById(userId).map(user -> {
            if (body.heightCm() != null) user.setHeightCm(body.heightCm());
            if (body.weightKg() != null) user.setWeightKg(body.weightKg());
            if (body.dateOfBirth() != null) user.setDateOfBirth(body.dateOfBirth());
            return ResponseEntity.ok(userRepository.save(user));
        }).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{userId}/daily-goal")
    public ResponseEntity<Double> getDailyWaterIntakeGoal(@PathVariable String userId) {
        return userRepository.findById(userId)
                .map(user -> ResponseEntity.ok(user.getDailyWaterIntakeGoal()))
                .orElse(ResponseEntity.notFound().build());
    }
}
