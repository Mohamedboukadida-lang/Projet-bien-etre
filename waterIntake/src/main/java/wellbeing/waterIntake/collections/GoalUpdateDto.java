package wellbeing.waterIntake.collections;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

/** @param newGoal daily goal in litres */
public record GoalUpdateDto(@NotNull @DecimalMin("0.5") @DecimalMax("10.0") Double newGoal) {
}
