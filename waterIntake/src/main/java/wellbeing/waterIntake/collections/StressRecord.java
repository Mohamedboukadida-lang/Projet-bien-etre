package wellbeing.waterIntake.collections;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;

/** Self-reported stress for one day (user's local date): 1 = very low, 5 = very high. */
@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
@Document
public class StressRecord {
    @Id
    private String id;
    private String userId;
    private LocalDate date;
    private int level;
    private String note;
}
