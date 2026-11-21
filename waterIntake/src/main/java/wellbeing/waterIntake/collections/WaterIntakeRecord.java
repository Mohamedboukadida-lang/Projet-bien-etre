package wellbeing.waterIntake.collections;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

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
}
