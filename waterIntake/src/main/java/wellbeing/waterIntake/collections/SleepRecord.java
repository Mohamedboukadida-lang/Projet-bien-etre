package wellbeing.waterIntake.collections;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** One night of sleep. Times are the user's local wall-clock times; {@code date} is the wake-up day. */
@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
@Document
public class SleepRecord {
    @Id
    private String id;
    private String userId;
    private LocalDate date;
    private LocalDateTime bedTime;
    private LocalDateTime wakeTime;
    private int durationMinutes;
}
