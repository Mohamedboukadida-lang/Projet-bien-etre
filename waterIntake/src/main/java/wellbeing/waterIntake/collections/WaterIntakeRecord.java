package wellbeing.waterIntake.collections;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
@Document
public class WaterIntakeRecord {
    @Id
    private String id;
    @Indexed
    private String userId;
    private double amount; // in liters
    private LocalDateTime dateTime; // UTC
    /** The user's local date when the drink was logged; null on records created before this field existed. */
    private LocalDate date;

    /** The day this drink counts for: the user's local date, or the UTC date for older records. */
    public LocalDate effectiveDate() {
        return date != null ? date : dateTime.toLocalDate();
    }
}
