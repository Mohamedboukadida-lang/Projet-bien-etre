package wellbeing.waterIntake.collections;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Past;

import java.time.LocalDate;

/** Partial update of a user's body data: fields left null are not changed. */
public record UserBodyDto(
        @DecimalMin("50") @DecimalMax("260") Double heightCm,
        @DecimalMin("20") @DecimalMax("400") Double weightKg,
        @Past LocalDate dateOfBirth) {
}
