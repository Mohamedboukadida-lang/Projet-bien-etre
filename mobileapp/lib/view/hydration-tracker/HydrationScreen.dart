import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/hydration-tracker/HistoricalIntakeTrends.dart';
import 'package:fitnessapp/view/hydration-tracker/HydrationGoalCell.dart';
import 'package:fitnessapp/view/hydration-tracker/HydrationTipOfTheDay.dart';
import 'package:fitnessapp/view/hydration-tracker/WaterLevelIndicator.dart';
import 'package:flutter/material.dart';

class HydrationScreen extends StatefulWidget {
  static const String routeName = "/HydrationScreen";

  const HydrationScreen({super.key, this.service});

  /// Injectable for tests; defaults to the real service.
  final HydrationService? service;

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  late final HydrationService _service = widget.service ?? HydrationService();
  final String _userId = ApiConfig.userId;

  double? _goal;
  double? _today;
  List<double> _week = const [];
  String? _error;
  bool _logging = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait<Object>([
        _service.fetchDailyGoal(_userId),
        _service.fetchCurrentIntake(_userId),
        _service.fetchWeeklySummary(_userId),
      ]);
      if (!mounted) return;
      setState(() {
        _goal = results[0] as double;
        _today = results[1] as double;
        _week = results[2] as List<double>;
        _error = null;
      });
    } on HydrationException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _log(double litres) async {
    setState(() => _logging = true);
    try {
      final ok = await _service.logWaterIntake(_userId, litres);
      if (!ok) throw const HydrationException("Could not log the water intake.");
      await _refresh();
      _toast("+${(litres * 1000).round()} ml logged");
    } on HydrationException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _askCustomAmount() async {
    final controller = TextEditingController();
    final ml = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Custom amount"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "ml", hintText: "e.g. 330"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value > 0 && value <= 5000) {
                Navigator.pop(context, value);
              }
            },
            child: const Text("Log"),
          ),
        ],
      ),
    );
    if (ml != null) await _log(ml / 1000);
  }

  Future<void> _editGoal() async {
    final controller =
        TextEditingController(text: _goal?.toStringAsFixed(1) ?? "");
    final goal = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Daily goal"),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              suffixText: "L", helperText: "Between 0.5 and 10 litres"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value >= 0.5 && value <= 10) {
                Navigator.pop(context, value);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (goal == null) return;
    try {
      final ok = await _service.updateDailyGoal(_userId, goal);
      if (!ok) throw const HydrationException("Could not update the goal.");
      await _refresh();
      _toast("Daily goal set to ${goal.toStringAsFixed(1)} L");
    } on HydrationException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrayColor,
      appBar: AppBar(
        backgroundColor: AppColors.lightGrayColor,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back, color: AppColors.blackColor),
          ),
        ),
        title: const Text(
          "Hydration Tracker",
          style: TextStyle(
              color: AppColors.blackColor,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) ...[
              _ErrorBanner(message: _error!, onRetry: _refresh),
              const SizedBox(height: 16),
            ],
            HydrationLevelIndicator(
              currentLevel: _today ?? 0,
              goal: _goal ?? 0,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HydrationGoalCell(
                    icon: "assets/icons/water_icon.png",
                    title: "Drunk today",
                    value: _today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HydrationGoalCell(
                    icon: "assets/icons/goal_icon.png",
                    title: "Daily goal",
                    value: _goal,
                    onTap: _goal == null ? null : _editGoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Log a drink",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final ml in const [250, 500])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _QuickAddButton(
                        label: "$ml ml",
                        icon: ml == 250
                            ? Icons.local_drink_outlined
                            : Icons.water_drop_outlined,
                        onTap: _logging || _goal == null
                            ? null
                            : () => _log(ml / 1000),
                      ),
                    ),
                  ),
                Expanded(
                  child: _QuickAddButton(
                    label: "Custom",
                    icon: Icons.add,
                    onTap: _logging || _goal == null ? null : _askCustomAmount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            HistoricalIntakeTrends(
              values: _week,
              goal: _goal ?? 0,
              loading: _week.isEmpty && _error == null,
            ),
            const SizedBox(height: 20),
            HydrationTipOfTheDay(),
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.primaryG)),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(icon, color: AppColors.whiteColor),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.whiteColor,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          TextButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}
