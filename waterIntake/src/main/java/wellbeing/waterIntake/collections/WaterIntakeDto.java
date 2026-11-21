package wellbeing.waterIntake.collections;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;

import java.time.LocalDateTime;

/**
 * @param amount   litres drunk, between 0.01 and 5
 * @param dateTime optional UTC time of the intake; defaults to now
 */
public record WaterIntakeDto(
        @NotBlank String userId,
        @DecimalMin("0.01") @DecimalMax("5.0") double amount,
        LocalDateTime dateTime) {
}
