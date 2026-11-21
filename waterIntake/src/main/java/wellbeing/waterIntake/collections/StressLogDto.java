package wellbeing.waterIntake.collections;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/** @param date the user's local date */
public record StressLogDto(
        @NotBlank String userId,
        @NotNull LocalDate date,
        @Min(1) @Max(5) int level,
        @Size(max = 280) String note) {
}
