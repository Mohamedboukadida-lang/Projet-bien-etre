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

/**
 * Days are the user's local days: the app sends its local date when logging and when asking for
 * a day or a week. {@code dateTime} values are UTC. When no date is given, today's UTC date is used.
 */
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

    /** Total litres drunk on the local {@code date} (today when omitted). */
    @GetMapping("/daily/{userId}")
    public double getDailyIntake(
            @PathVariable String userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate day = date != null ? date : LocalDate.now(clock);
        return recordsForLocalDays(userId, day, day)
                .stream().mapToDouble(WaterIntakeRecord::getAmount).sum();
    }

    /** Drinks logged on the local {@code date} (today when omitted), oldest first. */
    @GetMapping("/records/{userId}")
    public List<WaterIntakeRecord> getDayRecords(
            @PathVariable String userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate day = date != null ? date : LocalDate.now(clock);
        return recordsForLocalDays(userId, day, day);
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
        LocalDateTime dateTime = intakeDto.dateTime() != null ? intakeDto.dateTime() : LocalDateTime.now(clock);
        LocalDate date = intakeDto.date() != null ? intakeDto.date() : dateTime.toLocalDate();
        DateRanges.requireNotInFuture(date, clock);
        if (!userRepository.existsById(intakeDto.userId())) {
            return ResponseEntity.notFound().build();
        }
        WaterIntakeRecord record = new WaterIntakeRecord();
        record.setUserId(intakeDto.userId());
        record.setAmount(intakeDto.amount());
        record.setDateTime(dateTime);
        record.setDate(date);
        return ResponseEntity.ok(waterIntakeRecordRepository.save(record));
    }

    /**
     * Litres per local day for the week (Monday to Sunday) containing {@code date} (today when
     * omitted), with 0 for days without records.
     */
    @GetMapping("/weeklySummary/{userId}")
    public Map<LocalDate, Double> getWeeklyIntakeSummary(
            @PathVariable String userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate day = date != null ? date : LocalDate.now(clock);
        LocalDate startOfWeek = day.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        Map<LocalDate, Double> summary = new LinkedHashMap<>();
        for (int i = 0; i < 7; i++) {
            summary.put(startOfWeek.plusDays(i), 0.0);
        }
        recordsForLocalDays(userId, startOfWeek, startOfWeek.plusDays(6))
                .forEach(r -> summary.merge(r.effectiveDate(), r.getAmount(), Double::sum));
        return summary;
    }

    private List<WaterIntakeRecord> recordsBetween(String userId, LocalDateTime start, LocalDateTime end) {
        return waterIntakeRecordRepository.findInRange(userId, start, end);
    }

    private List<WaterIntakeRecord> recordsForLocalDays(String userId, LocalDate from, LocalDate to) {
        return waterIntakeRecordRepository.findForLocalDays(
                userId, from, to, from.atStartOfDay(), to.plusDays(1).atStartOfDay());
    }
}
