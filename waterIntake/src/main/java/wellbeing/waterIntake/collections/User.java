package wellbeing.waterIntake.collections;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
@Document
public class User {
    @Id
    private String id;
    private String username;
    private String email;
    private double dailyWaterIntakeGoal; // in liters
    /** Body measurements; null until the user enters them. */
    private Double heightCm;
    private Double weightKg;
    /** Stored instead of an age so the age stays correct over time. */
    private LocalDate dateOfBirth;

    public User(String id, String username, String email, double dailyWaterIntakeGoal) {
        this(id, username, email, dailyWaterIntakeGoal, null, null, null);
    }
}
