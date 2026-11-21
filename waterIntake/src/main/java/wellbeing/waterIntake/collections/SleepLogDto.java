package wellbeing.waterIntake.collections;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDateTime;

/** Bed and wake-up times in the user's local time, e.g. {@code 2026-11-20T23:15:00}. */
public record SleepLogDto(@NotBlank String userId, @NotNull LocalDateTime bedTime, @NotNull LocalDateTime wakeTime) {
}
