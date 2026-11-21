import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:http/http.dart' as http;

class HydrationException implements Exception {
  const HydrationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client of the water-intake service. Amounts are in litres.
class HydrationService {
  HydrationService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.hydrationBaseUrl;

  final http.Client _client;
  final String baseUrl;

  static const _jsonHeaders = {'Content-Type': 'application/json; charset=UTF-8'};

  Future<double> fetchDailyGoal(String userId) async {
    final response = await _get('/users/$userId/daily-goal');
    return double.parse(response.body);
  }

  Future<bool> updateDailyGoal(String userId, double newGoal) async {
    final response = await _send(() => _client.post(
          Uri.parse('$baseUrl/waterIntake/updateGoal/$userId'),
          headers: _jsonHeaders,
          body: jsonEncode({'newGoal': newGoal}),
        ));
    return response.statusCode == 200;
  }

  /// Litres drunk today (UTC day, as computed by the service).
  Future<double> fetchCurrentIntake(String userId) async {
    final response = await _get('/waterIntake/daily/$userId');
    return double.parse(response.body);
  }

  Future<bool> logWaterIntake(String userId, double amount) async {
    final response = await _send(() => _client.post(
          Uri.parse('$baseUrl/waterIntake/logIntake'),
          headers: _jsonHeaders,
          body: jsonEncode({'userId': userId, 'amount': amount}),
        ));
    return response.statusCode == 200;
  }

  /// Litres per day for the current week, Monday first (7 values).
  Future<List<double>> fetchWeeklySummary(String userId) async {
    final response = await _get('/waterIntake/weeklySummary/$userId');
    final Map<String, dynamic> data = jsonDecode(response.body);
    final days = data.keys.toList()..sort();
    return [for (final day in days) (data[day] as num).toDouble()];
  }

  Future<http.Response> _get(String path) async {
    final response =
        await _send(() => _client.get(Uri.parse('$baseUrl$path')));
    if (response.statusCode != 200) {
      throw HydrationException(
          'Hydration service answered HTTP ${response.statusCode} for $path');
    }
    return response;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConfig.timeout);
    } on HydrationException {
      rethrow;
    } catch (_) {
      throw HydrationException(
          'Cannot reach the hydration service at $baseUrl. Is the back-end running?');
    }
  }
}
