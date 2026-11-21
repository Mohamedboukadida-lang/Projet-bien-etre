package wellbeing.waterIntake.controller;

import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import wellbeing.waterIntake.collections.StressLogDto;
import wellbeing.waterIntake.collections.StressRecord;
import wellbeing.waterIntake.repository.StressRecordRepository;
import wellbeing.waterIntake.repository.UserRepository;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/stress")
public class StressController {

    private final StressRecordRepository stressRecords;
    private final UserRepository users;
    private final Clock clock;

    public StressController(StressRecordRepository stressRecords, UserRepository users, Clock clock) {
        this.stressRecords = stressRecords;
        this.users = users;
        this.clock = clock;
    }

    /** Records the stress level for a day; logging again for the same day replaces it. */
    @PostMapping("/log")
    public ResponseEntity<StressRecord> logStress(@Valid @RequestBody StressLogDto dto) {
        DateRanges.requireNotInFuture(dto.date(), clock);
        if (!users.existsById(dto.userId())) {
            return ResponseEntity.notFound().build();
        }
        StressRecord record = stressRecords.findByUserIdAndDate(dto.userId(), dto.date()).orElseGet(StressRecord::new);
        record.setUserId(dto.userId());
        record.setDate(dto.date());
        record.setLevel(dto.level());
        record.setNote(dto.note() == null || dto.note().isBlank() ? null : dto.note().strip());
        return ResponseEntity.ok(stressRecords.save(record));
    }

    /** Entries between {@code from} and {@code to} (inclusive), oldest first. */
    @GetMapping("/{userId}")
    public List<StressRecord> getStress(@PathVariable String userId,
                                        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                        @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        DateRanges.requireValidRange(from, to);
        return stressRecords.findInRange(userId, from, to);
    }
}
