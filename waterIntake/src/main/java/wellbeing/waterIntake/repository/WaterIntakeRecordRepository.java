package wellbeing.waterIntake.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import wellbeing.waterIntake.collections.WaterIntakeRecord;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public interface WaterIntakeRecordRepository extends MongoRepository<WaterIntakeRecord, String> {

    /** Records with {@code start <= dateTime < end}, oldest first. */
    @Query(value = "{ 'userId': ?0, 'dateTime': { $gte: ?1, $lt: ?2 } }", sort = "{ 'dateTime': 1 }")
    List<WaterIntakeRecord> findInRange(String userId, LocalDateTime start, LocalDateTime end);

    /**
     * Records whose local {@code date} is between {@code from} and {@code to} (inclusive), plus older
     * records without a local date whose UTC {@code dateTime} is in {@code [legacyStart, legacyEnd)}.
     */
    @Query(value = "{ 'userId': ?0, $or: [ { 'date': { $gte: ?1, $lte: ?2 } },"
            + " { 'date': null, 'dateTime': { $gte: ?3, $lt: ?4 } } ] }", sort = "{ 'dateTime': 1 }")
    List<WaterIntakeRecord> findForLocalDays(String userId, LocalDate from, LocalDate to,
                                             LocalDateTime legacyStart, LocalDateTime legacyEnd);
}
