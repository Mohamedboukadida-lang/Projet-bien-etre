import 'package:fitnessapp/service/HydrationService.dart';

/// Labels for stress levels 1..5 (index 0 is level 1).
const stressLevelLabels = ['Very low', 'Low', 'Moderate', 'High', 'Very high'];
const stressLevelEmojis = ['😌', '🙂', '😐', '😟', '😫'];

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String formatLitres(double litres) =>
    litres >= 1 ? '${litres.toStringAsFixed(2)} L' : '${(litres * 1000).round()} ml';

String formatClock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Drinks grouped by local time of day.
class IntakeSlot {
  const IntakeSlot(this.label, this.litres);

  final String label;
  final double litres;
}

const _slots = [
  ('Before 9am', 0, 9),
  ('9am - 12pm', 9, 12),
  ('12pm - 3pm', 12, 15),
  ('3pm - 6pm', 15, 18),
  ('After 6pm', 18, 24),
];

List<IntakeSlot> intakeByTimeOfDay(List<IntakeEntry> entries) => [
      for (final (label, from, to) in _slots)
        IntakeSlot(
          label,
          entries
              .where((e) => e.time.hour >= from && e.time.hour < to)
              .fold(0.0, (sum, e) => sum + e.amount),
        ),
    ];
