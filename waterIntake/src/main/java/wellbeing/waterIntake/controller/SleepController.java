package wellbeing.waterIntake.controller;

import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import wellbeing.waterIntake.collections.SleepLogDto;
import wellbeing.waterIntake.collections.SleepRecord;
import wellbeing.waterIntake.repository.SleepRecordRepository;
import wellbeing.waterIntake.repository.UserRepository;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/sleep")
public class SleepController {

    static final Duration MIN_SLEEP = Duration.ofMinutes(10);
    static final Duration MAX_SLEEP = Duration.ofHours(24);

    private final SleepRecordRepository sleepRecords;
    private final UserRepository users;
    private final Clock clock;

    public SleepController(SleepRecordRepository sleepRecords, UserRepository users, Clock clock) {
        this.sleepRecords = sleepRecords;
        this.users = users;
        this.clock = clock;
    }

    /** Records one night; logging again for the same wake-up day replaces it. */
    @PostMapping("/log")
    public ResponseEntity<SleepRecord> logSleep(@Valid @RequestBody SleepLogDto dto) {
        Duration duration = Duration.between(dto.bedTime(), dto.wakeTime());
        if (duration.compareTo(MIN_SLEEP) < 0 || duration.compareTo(MAX_SLEEP) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "wakeTime must be between 10 minutes and 24 hours after bedTime");
        }
        LocalDate date = dto.wakeTime().toLocalDate();
        DateRanges.requireNotInFuture(date, clock);
        if (!users.existsById(dto.userId())) {
            return ResponseEntity.notFound().build();
        }
        SleepRecord record = sleepRecords.findByUserIdAndDate(dto.userId(), date).orElseGet(SleepRecord::new);
        record.setUserId(dto.userId());
        record.setDate(date);
        record.setBedTime(dto.bedTime());
        record.setWakeTime(dto.wakeTime());
        record.setDurationMinutes((int) duration.toMinutes());
        return ResponseEntity.ok(sleepRecords.save(record));
    }

    /** Nights whose wake-up day is between {@code from} and {@code to} (inclusive), oldest first. */
    @GetMapping("/{userId}")
    public List<SleepRecord> getSleep(@PathVariable String userId,
                                      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        DateRanges.requireValidRange(from, to);
        return sleepRecords.findInRange(userId, from, to);
    }
}
