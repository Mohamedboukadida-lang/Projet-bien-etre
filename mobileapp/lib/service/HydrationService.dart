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

  /// Litres drunk today (UTC day, as computed by the service).
  Future<double> fetchCurrentIntake(String userId) async =>
      double.parse(await _api.get('/waterIntake/daily/$userId'));

  Future<bool> logWaterIntake(String userId, double amount) async {
    await _api.post('/waterIntake/logIntake', {'userId': userId, 'amount': amount});
    return true;
  }

  /// Litres per day for the current week, Monday first (7 values).
  Future<List<double>> fetchWeeklySummary(String userId) async {
    final Map<String, dynamic> data =
        jsonDecode(await _api.get('/waterIntake/weeklySummary/$userId'));
    final days = data.keys.toList()..sort();
    return [for (final day in days) (data[day] as num).toDouble()];
  }

  /// Drinks logged during today's UTC day, the same day [fetchCurrentIntake]
  /// sums, so the two always agree.
  Future<List<IntakeEntry>> fetchTodayEntries(String userId, {DateTime? now}) async {
    final utc = (now ?? DateTime.now()).toUtc();
    final start = DateTime.utc(utc.year, utc.month, utc.day);
    final end = start.add(const Duration(days: 1));
    String iso(DateTime d) => d.toIso8601String().replaceFirst('Z', '');
    final List<dynamic> data = jsonDecode(await _api.get(
        '/waterIntake/range/$userId',
        query: {'startDate': iso(start), 'endDate': iso(end)}));
    return [for (final e in data) IntakeEntry.fromJson(e as Map<String, dynamic>)];
  }
}
