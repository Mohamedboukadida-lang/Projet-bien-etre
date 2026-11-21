import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups drinks by local time of day', () {
    IntakeEntry at(int hour, double litres) =>
        IntakeEntry(amount: litres, time: DateTime(2026, 11, 21, hour, 30));

    final slots = intakeByTimeOfDay([at(7, 0.25), at(8, 0.25), at(13, 0.5), at(22, 0.3)]);

    expect(slots.map((s) => s.label),
        ['Before 9am', '9am - 12pm', '12pm - 3pm', '3pm - 6pm', 'After 6pm']);
    expect(slots.map((s) => s.litres), [0.5, 0.0, 0.5, 0.0, 0.3]);
  });

  test('formats durations and amounts', () {
    expect(formatDuration(const Duration(hours: 7, minutes: 45)), '7h 45m');
    expect(formatDuration(const Duration(hours: 8)), '8h');
    expect(formatDuration(const Duration(minutes: 40)), '40m');
    expect(formatLitres(1.25), '1.25 L');
    expect(formatLitres(0.75), '750 ml');
    expect(formatClock(DateTime(2026, 1, 1, 23, 5)), '11:05 pm');
    expect(formatClock(DateTime(2026, 1, 1, 0, 30)), '12:30 am');
  });

  test('parses service UTC times as local', () {
    final e = IntakeEntry.fromJson({'amount': 0.25, 'dateTime': '2026-11-21T10:00:00.123'});
    expect(e.time.isUtc, isFalse);
    expect(e.time.toUtc(), DateTime.utc(2026, 11, 21, 10, 0, 0, 123));
  });
}
