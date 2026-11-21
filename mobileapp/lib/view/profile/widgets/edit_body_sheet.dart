import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Values entered in [showEditBodySheet]; null means "not entered".
typedef BodyUpdate = ({double? heightCm, double? weightKg, DateTime? dateOfBirth});

/// Lets the user enter height, weight and date of birth. Returns null when
/// cancelled. Ranges match the tracking service's validation.
Future<BodyUpdate?> showEditBodySheet(BuildContext context, AppUser? user) {
  String initial(double? v) => v == null ? '' : _trim(v);
  final height = TextEditingController(text: initial(user?.heightCm));
  final weight = TextEditingController(text: initial(user?.weightKg));
  DateTime? dob = user?.dateOfBirth;

  return showModalBottomSheet<BodyUpdate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.whiteColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      double? parse(TextEditingController c) =>
          double.tryParse(c.text.trim().replaceAll(',', '.'));
      String? rangeError(TextEditingController c, double min, double max, String unit) {
        if (c.text.trim().isEmpty) return null;
        final v = parse(c);
        return v == null || v < min || v > max ? 'Between ${_trim(min)} and ${_trim(max)} $unit' : null;
      }

      final heightError = rangeError(height, 50, 260, 'cm');
      final weightError = rangeError(weight, 20, 400, 'kg');
      final canSave = heightError == null && weightError == null;

      Future<void> pickDob() async {
        final today = DateUtils.dateOnly(DateTime.now());
        final picked = await showDatePicker(
          context: context,
          initialDate: dob ?? DateTime(today.year - 25, today.month, today.day),
          firstDate: DateTime(1900),
          lastDate: today.subtract(const Duration(days: 1)),
          helpText: 'Date of birth',
        );
        if (picked != null) setState(() => dob = picked);
      }

      InputDecoration field(String label, String suffix, String? error) => InputDecoration(
            labelText: label,
            suffixText: suffix,
            errorText: error,
            filled: true,
            fillColor: AppColors.lightGrayColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          );

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.midGrayColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text("Your body data",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                key: const Key('height-field'),
                controller: height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: field("Height", "cm", heightError),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('weight-field'),
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: field("Weight", "kg", weightError),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined, color: AppColors.primaryColor1),
                title: const Text("Date of birth"),
                trailing: Text(
                  dob == null ? "Not set" : _formatDate(dob!),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onTap: pickDob,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: canSave
                    ? () => Navigator.pop<BodyUpdate>(context,
                        (heightCm: parse(height), weightKg: parse(weight), dateOfBirth: dob))
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

/// 172.0 -> "172", 172.5 -> "172.5".
String _trim(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// For the profile cells: "172cm", "64.5kg"; "–" when missing.
String formatMeasure(double? v, String unit) => v == null ? '–' : '${_trim(v)}$unit';
