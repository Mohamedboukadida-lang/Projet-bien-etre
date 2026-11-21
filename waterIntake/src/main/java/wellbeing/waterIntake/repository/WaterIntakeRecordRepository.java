package wellbeing.waterIntake.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import wellbeing.waterIntake.collections.WaterIntakeRecord;

import java.time.LocalDateTime;
import java.util.List;

public interface WaterIntakeRecordRepository extends MongoRepository<WaterIntakeRecord, String> {

    /** Records with {@code start <= dateTime < end}, oldest first. */
    @Query(value = "{ 'userId': ?0, 'dateTime': { $gte: ?1, $lt: ?2 } }", sort = "{ 'dateTime': 1 }")
    List<WaterIntakeRecord> findInRange(String userId, LocalDateTime start, LocalDateTime end);
}
