import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:flutter/material.dart';

/// Asks for last night's bed and wake-up times. Returns `(bedTime, wakeTime)`
/// in local time, or null when cancelled.
Future<(DateTime, DateTime)?> showLogSleepSheet(BuildContext context,
    {DateTime? initialBed, DateTime? initialWake}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var bed = TimeOfDay.fromDateTime(initialBed ?? today.subtract(const Duration(hours: 1)));
  // Default wake-up is 7:00, or now when the sheet is opened before 7 am.
  final sevenAm = today.add(const Duration(hours: 7));
  var wake = TimeOfDay.fromDateTime(
      initialWake ?? (now.isBefore(sevenAm) ? now : sevenAm));

  // Bed times from noon onwards are the previous evening; earlier ones are after midnight.
  DateTime bedTime() => bed.hour >= 12
      ? today.subtract(const Duration(days: 1)).add(Duration(hours: bed.hour, minutes: bed.minute))
      : today.add(Duration(hours: bed.hour, minutes: bed.minute));
  DateTime wakeTime() => today.add(Duration(hours: wake.hour, minutes: wake.minute));

  return showModalBottomSheet<(DateTime, DateTime)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.whiteColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final duration = wakeTime().difference(bedTime());
      String? error;
      if (duration.inMinutes < 10) {
        error = "Wake-up time must be after bedtime.";
      } else if (duration.inHours >= 24) {
        error = "That's more than 24 hours.";
      } else if (wakeTime().isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
        error = "Wake-up time is in the future.";
      }
      Future<void> pick(bool isBed) async {
        final picked = await showTimePicker(context: context, initialTime: isBed ? bed : wake);
        if (picked != null) setState(() => isBed ? bed = picked : wake = picked);
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const Text("Last night's sleep",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _TimeTile(icon: Icons.bedtime_outlined, label: "Went to bed",
                  value: formatClock(bedTime()), onTap: () => pick(true)),
              _TimeTile(icon: Icons.wb_sunny_outlined, label: "Woke up",
                  value: formatClock(wakeTime()), onTap: () => pick(false)),
              const SizedBox(height: 8),
              Text(
                error ?? "Total: ${formatDuration(duration)}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: error == null ? AppColors.primaryColor1 : Colors.redAccent,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: error == null
                    ? () => Navigator.pop(context, (bedTime(), wakeTime()))
                    : null,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor1,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      );
    }),
  );
}

/// Asks for today's stress level (1-5) and an optional note. Returns
/// `(level, note)` or null when cancelled.
Future<(int, String?)?> showLogStressSheet(BuildContext context, {int? initialLevel, String? initialNote}) {
  int? level = initialLevel;
  final note = TextEditingController(text: initialNote ?? '');
  return showModalBottomSheet<(int, String?)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.whiteColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const Text("How stressed do you feel today?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int l = 1; l <= 5; l++)
                    _LevelOption(
                      emoji: stressLevelEmojis[l - 1],
                      label: stressLevelLabels[l - 1],
                      selected: level == l,
                      onTap: () => setState(() => level = l),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: note,
                maxLength: 280,
                decoration: InputDecoration(
                  hintText: "What's on your mind? (optional)",
                  filled: true,
                  fillColor: AppColors.lightGrayColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: level == null ? null : () => Navigator.pop(context, (level!, note.text)),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor1,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: AppColors.midGrayColor, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.primaryColor1),
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        onTap: onTap,
      );
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({required this.emoji, required this.label, required this.selected, required this.onTap});

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondaryColor1.withValues(alpha: 0.15) : null,
            border: Border.all(
                color: selected ? AppColors.secondaryColor1 : AppColors.lightGrayColor, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.blackColor)),
          ]),
        ),
      );
}
