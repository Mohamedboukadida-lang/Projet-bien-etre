import 'package:fitnessapp/common_widgets/round_button.dart';
import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/service/api_client.dart';
import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/ActivityRow.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:fitnessapp/view/home/widgets/log_sheets.dart';
import 'package:fitnessapp/view/home/widgets/sleep_card.dart';
import 'package:fitnessapp/view/home/widgets/stress_chart.dart';
import 'package:fitnessapp/view/home/widgets/stress_today_card.dart';
import 'package:fitnessapp/view/home/widgets/water_intake_card.dart';
import 'package:fitnessapp/view/hydration-tracker/HydrationScreen.dart';
import 'package:flutter/material.dart';

import '../notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/HomeScreen";

  const HomeScreen({super.key, this.hydrationService, this.wellbeingService});

  /// Injectable for tests; default to the real services.
  final HydrationService? hydrationService;
  final WellbeingService? wellbeingService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HydrationService _hydration =
      widget.hydrationService ?? HydrationService();
  late final WellbeingService _wellbeing =
      widget.wellbeingService ?? WellbeingService();
  final String _userId = ApiConfig.userId;

  /// Static suggestions (content, not user data).
  static const List<Map<String, dynamic>> _focusSuggestions = [
    {
      "name": "Morning Yoga Flow",
      "image": "assets/icons/meditation1.png",
      "duration": "15 mins",
      "type": "Yoga",
      "description": "A gentle flow to start your day with energy and balance."
    },
    {
      "name": "Guided Meditation for Focus",
      "image": "assets/images/Workout2.png",
      "duration": "10 mins",
      "type": "Meditation",
      "description": "Improve your concentration and calm your mind."
    },
    {
      "name": "Relaxing Rain Sounds",
      "image": "assets/icons/musicrelaxing1.png",
      "duration": "30 mins",
      "type": "Music",
      "description": "Soothing rain sounds to help you relax and fall asleep."
    },
  ];

  UserProfile? _profile;
  double? _todayIntake;
  List<IntakeEntry>? _intakeEntries;
  List<SleepEntry>? _sleep;
  List<StressEntry>? _stress;
  String? _error;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads every section independently so one failure doesn't blank the rest.
  Future<void> _load() async {
    final today = _today;
    final from = today.subtract(const Duration(days: 6));
    String? firstError;

    Future<T?> attempt<T>(Future<T> Function() call) async {
      try {
        return await call();
      } on ApiException catch (e) {
        firstError ??= e.message;
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      attempt(() => _wellbeing.fetchUser(_userId)),
      attempt(() => _hydration.fetchCurrentIntake(_userId)),
      attempt(() => _hydration.fetchTodayEntries(_userId)),
      attempt(() => _wellbeing.fetchSleep(_userId, from, today)),
      attempt(() => _wellbeing.fetchStress(_userId, from, today)),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as UserProfile?;
      _todayIntake = results[1] as double?;
      _intakeEntries = results[2] as List<IntakeEntry>?;
      _sleep = results[3] as List<SleepEntry>?;
      _stress = results[4] as List<StressEntry>?;
      _error = firstError;
    });
  }

  StressEntry? get _todayStress =>
      _stress?.where((e) => isSameDay(e.date, _today)).firstOrNull;

  Future<void> _openHydration() async {
    await Navigator.pushNamed(context, HydrationScreen.routeName);
    _load();
  }

  Future<void> _logSleep() async {
    final existing = _sleep?.where((e) => isSameDay(e.date, _today)).firstOrNull;
    final result = await showLogSleepSheet(context,
        initialBed: existing?.bedTime, initialWake: existing?.wakeTime);
    if (result == null) return;
    await _save(() => _wellbeing.logSleep(_userId, result.$1, result.$2),
        "Sleep saved: ${formatDuration(result.$2.difference(result.$1))}");
  }

  Future<void> _logStress() async {
    final existing = _todayStress;
    final result = await showLogStressSheet(context,
        initialLevel: existing?.level, initialNote: existing?.note);
    if (result == null) return;
    await _save(() => _wellbeing.logStress(_userId, _today, result.$1, note: result.$2),
        "Stress logged: ${stressLevelLabels[result.$1 - 1]}");
  }

  Future<void> _save(Future<Object> Function() call, String success) async {
    try {
      await call();
      await _load();
      _toast(success);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    final name = _profile?.name;
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome Back,",
                          style: TextStyle(color: AppColors.midGrayColor, fontSize: 12),
                        ),
                        Text(
                          name == null || name.isEmpty ? "…" : name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.blackColor,
                            fontSize: 20,
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, NotificationScreen.routeName);
                      },
                      icon: Image.asset(
                        "assets/icons/notification_icon.png",
                        width: 25,
                        height: 25,
                        fit: BoxFit.fitHeight,
                      ))
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!, onRetry: _load),
              ],
              SizedBox(height: media.width * 0.05),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: AppColors.primaryColor1.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today Target",
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      height: 30,
                      child: RoundButton(
                        title: "check",
                        type: RoundButtonType.primaryBG,
                        onPressed: _openHydration,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: media.width * 0.05),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WaterIntakeCard(
                      height: media.width * 0.95,
                      today: _todayIntake,
                      goal: _profile?.dailyGoal,
                      entries: _intakeEntries,
                      onTap: _openHydration,
                    ),
                  ),
                  SizedBox(width: media.width * 0.05),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SleepCard(
                          height: media.width * 0.5,
                          today: _today,
                          entries: _sleep,
                          onTap: _logSleep,
                        ),
                        SizedBox(height: media.width * 0.05),
                        StressTodayCard(
                          height: media.width * 0.4,
                          entry: _todayStress,
                          onTap: _logStress,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: media.width * 0.1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      "Stress tracker",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.blackColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 35,
                    child: FilledButton.icon(
                      onPressed: _logStress,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(_todayStress == null ? "Log today" : "Update today"),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor1,
                        textStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                "Last 7 days",
                style: TextStyle(color: AppColors.grayColor, fontSize: 12),
              ),
              SizedBox(height: media.width * 0.05),
              StressChart(
                today: _today,
                entries: _stress,
                height: media.width * 0.5,
              ),
              SizedBox(height: media.width * 0.05),
              const Text(
                "Today's Focus",
                style: TextStyle(
                    color: AppColors.blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final activity in _focusSuggestions) ActivityRow(wObj: activity),
              SizedBox(height: media.width * 0.1),
            ],
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
