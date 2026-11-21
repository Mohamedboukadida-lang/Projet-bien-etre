package wellbeing.waterIntake.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import wellbeing.waterIntake.collections.StressRecord;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface StressRecordRepository extends MongoRepository<StressRecord, String> {

    Optional<StressRecord> findByUserIdAndDate(String userId, LocalDate date);

    /** Records with {@code from <= date <= to}, oldest first. */
    @Query(value = "{ 'userId': ?0, 'date': { $gte: ?1, $lte: ?2 } }", sort = "{ 'date': 1 }")
    List<StressRecord> findInRange(String userId, LocalDate from, LocalDate to);
}
