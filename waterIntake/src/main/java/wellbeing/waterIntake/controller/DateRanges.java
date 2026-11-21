package wellbeing.waterIntake.controller;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/** Validation shared by the daily-entry endpoints (sleep, stress). */
final class DateRanges {

    static final int MAX_DAYS = 366;

    private DateRanges() {
    }

    static void requireValidRange(LocalDate from, LocalDate to) {
        if (to.isBefore(from) || ChronoUnit.DAYS.between(from, to) >= MAX_DAYS) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "'from' must be on or before 'to' and the range at most " + MAX_DAYS + " days");
        }
    }

    /** Local dates come from the client; allow one day ahead of UTC for time zones east of UTC. */
    static void requireNotInFuture(LocalDate date, Clock clock) {
        if (date.isAfter(LocalDate.now(clock).plusDays(1))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "date must not be in the future");
        }
    }
}
