package wellbeing.waterIntake.controller;

import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import wellbeing.waterIntake.collections.GoalUpdateDto;
import wellbeing.waterIntake.collections.WaterIntakeDto;
import wellbeing.waterIntake.collections.WaterIntakeRecord;
import wellbeing.waterIntake.repository.UserRepository;
import wellbeing.waterIntake.repository.WaterIntakeRecordRepository;

import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** All dates and times are UTC. */
@RestController
@RequestMapping("/waterIntake")
public class WaterIntakeController {

    private final WaterIntakeRecordRepository waterIntakeRecordRepository;
    private final UserRepository userRepository;
    private final Clock clock;

    public WaterIntakeController(WaterIntakeRecordRepository waterIntakeRecordRepository,
                                 UserRepository userRepository,
                                 Clock clock) {
        this.waterIntakeRecordRepository = waterIntakeRecordRepository;
        this.userRepository = userRepository;
        this.clock = clock;
    }

    /** Total litres drunk on {@code date} (today when omitted). */
    @GetMapping("/daily/{userId}")
    public double getDailyIntake(
            @PathVariable String userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate day = date != null ? date : LocalDate.now(clock);
        return recordsBetween(userId, day.atStartOfDay(), day.plusDays(1).atStartOfDay())
                .stream().mapToDouble(WaterIntakeRecord::getAmount).sum();
    }

    @PostMapping("/updateGoal/{userId}")
    public ResponseEntity<Void> updateDailyWaterIntakeGoal(@PathVariable String userId,
                                                           @Valid @RequestBody GoalUpdateDto body) {
        return userRepository.findById(userId).map(user -> {
            user.setDailyWaterIntakeGoal(body.newGoal());
            userRepository.save(user);
            return ResponseEntity.ok().<Void>build();
        }).orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/range/{userId}")
    public List<WaterIntakeRecord> getRecordsByDateRange(
            @PathVariable String userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return recordsBetween(userId, startDate, endDate);
    }

    @PostMapping("/logIntake")
    public ResponseEntity<WaterIntakeRecord> logWaterIntake(@Valid @RequestBody WaterIntakeDto intakeDto) {
        if (!userRepository.existsById(intakeDto.userId())) {
            return ResponseEntity.notFound().build();
        }
        WaterIntakeRecord record = new WaterIntakeRecord();
        record.setUserId(intakeDto.userId());
        record.setAmount(intakeDto.amount());
        record.setDateTime(intakeDto.dateTime() != null ? intakeDto.dateTime() : LocalDateTime.now(clock));
        return ResponseEntity.ok(waterIntakeRecordRepository.save(record));
    }

    /** Litres per day for the current week, Monday to Sunday, with 0 for days without records. */
    @GetMapping("/weeklySummary/{userId}")
    public Map<LocalDate, Double> getWeeklyIntakeSummary(@PathVariable String userId) {
        LocalDate startOfWeek = LocalDate.now(clock).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        Map<LocalDate, Double> summary = new LinkedHashMap<>();
        for (int i = 0; i < 7; i++) {
            summary.put(startOfWeek.plusDays(i), 0.0);
        }
        recordsBetween(userId, startOfWeek.atStartOfDay(), startOfWeek.plusDays(7).atStartOfDay())
                .forEach(r -> summary.merge(r.getDateTime().toLocalDate(), r.getAmount(), Double::sum));
        return summary;
    }

    private List<WaterIntakeRecord> recordsBetween(String userId, LocalDateTime start, LocalDateTime end) {
        return waterIntakeRecordRepository
                .findInRange(userId, start, end);
    }
}
