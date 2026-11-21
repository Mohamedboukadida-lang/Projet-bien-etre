import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/api_client.dart';
import 'package:http/http.dart' as http;

/// Kept for existing callers; hydration errors are plain [ApiException]s.
typedef HydrationException = ApiException;

/// One logged drink. [time] is in the device's local time zone.
class IntakeEntry {
  const IntakeEntry({required this.amount, required this.time});

  /// The service stores UTC date-times without an offset.
  factory IntakeEntry.fromJson(Map<String, dynamic> json) => IntakeEntry(
        amount: (json['amount'] as num).toDouble(),
        time: DateTime.parse('${json['dateTime']}Z').toLocal(),
      );

  final double amount;
  final DateTime time;
}

/// Client of the water-intake endpoints. Amounts are in litres.
class HydrationService {
  HydrationService({http.Client? client, String? baseUrl})
      : _api = ApiClient(
            client: client,
            baseUrl: baseUrl ?? ApiConfig.hydrationBaseUrl,
            serviceName: 'hydration');

  final ApiClient _api;

  String get baseUrl => _api.baseUrl;

  Future<double> fetchDailyGoal(String userId) async =>
      double.parse(await _api.get('/users/$userId/daily-goal'));

  Future<bool> updateDailyGoal(String userId, double newGoal) async {
    await _api.post('/waterIntake/updateGoal/$userId', {'newGoal': newGoal});
    return true;
  }

  /// Litres drunk today (the device's local day).
  Future<double> fetchCurrentIntake(String userId, {DateTime? now}) async =>
      double.parse(await _api.get('/waterIntake/daily/$userId',
          query: {'date': localDate(now ?? DateTime.now())}));

  /// Logs a drink now, counted for today (the device's local day). The time
  /// (UTC) and the local date describe the same moment.
  Future<bool> logWaterIntake(String userId, double amount, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    await _api.post('/waterIntake/logIntake', {
      'userId': userId,
      'amount': amount,
      'dateTime': at.toUtc().toIso8601String().replaceFirst('Z', ''),
      'date': localDate(at),
    });
    return true;
  }

  /// Litres per local day for the current week, Monday first (7 values).
  Future<List<double>> fetchWeeklySummary(String userId, {DateTime? now}) async {
    final Map<String, dynamic> data = jsonDecode(await _api.get(
        '/waterIntake/weeklySummary/$userId',
        query: {'date': localDate(now ?? DateTime.now())}));
    final days = data.keys.toList()..sort();
    return [for (final day in days) (data[day] as num).toDouble()];
  }

  /// Drinks logged today (the device's local day), the same ones
  /// [fetchCurrentIntake] sums.
  Future<List<IntakeEntry>> fetchTodayEntries(String userId, {DateTime? now}) async {
    final List<dynamic> data = jsonDecode(await _api.get(
        '/waterIntake/records/$userId',
        query: {'date': localDate(now ?? DateTime.now())}));
    return [for (final e in data) IntakeEntry.fromJson(e as Map<String, dynamic>)];
  }

  /// `YYYY-MM-DD` of [d] in the device's time zone.
  static String localDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
  }
}
