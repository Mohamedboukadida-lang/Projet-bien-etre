import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/api_client.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  const UserProfile({required this.id, required this.name, required this.dailyGoal});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: (json['username'] as String?)?.trim() ?? '',
        dailyGoal: (json['dailyWaterIntakeGoal'] as num? ?? 0).toDouble(),
      );

  final String id;
  final String name;

  /// Litres.
  final double dailyGoal;
}

/// One night of sleep; [date] is the local wake-up day.
class SleepEntry {
  const SleepEntry({required this.date, required this.bedTime, required this.wakeTime, required this.duration});

  factory SleepEntry.fromJson(Map<String, dynamic> json) => SleepEntry(
        date: DateTime.parse(json['date'] as String),
        bedTime: DateTime.parse(json['bedTime'] as String),
        wakeTime: DateTime.parse(json['wakeTime'] as String),
        duration: Duration(minutes: json['durationMinutes'] as int),
      );

  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final Duration duration;
}

/// Self-reported stress for a local day: 1 (very low) to 5 (very high).
class StressEntry {
  const StressEntry({required this.date, required this.level, this.note});

  factory StressEntry.fromJson(Map<String, dynamic> json) => StressEntry(
        date: DateTime.parse(json['date'] as String),
        level: json['level'] as int,
        note: json['note'] as String?,
      );

  final DateTime date;
  final int level;
  final String? note;
}

/// Client of the user, sleep and stress endpoints of the tracking service.
/// Sleep and stress use the device's local dates and times.
class WellbeingService {
  WellbeingService({http.Client? client, String? baseUrl})
      : _api = ApiClient(
            client: client,
            baseUrl: baseUrl ?? ApiConfig.hydrationBaseUrl,
            serviceName: 'tracking');

  final ApiClient _api;

  Future<UserProfile> fetchUser(String userId) async =>
      UserProfile.fromJson(jsonDecode(await _api.get('/users/$userId')));

  Future<List<SleepEntry>> fetchSleep(String userId, DateTime from, DateTime to) async {
    final List<dynamic> data = jsonDecode(await _api.get('/sleep/$userId',
        query: {'from': _date(from), 'to': _date(to)}));
    return [for (final e in data) SleepEntry.fromJson(e as Map<String, dynamic>)];
  }

  Future<SleepEntry> logSleep(String userId, DateTime bedTime, DateTime wakeTime) async =>
      SleepEntry.fromJson(jsonDecode(await _api.post('/sleep/log', {
        'userId': userId,
        'bedTime': _localDateTime(bedTime),
        'wakeTime': _localDateTime(wakeTime),
      })));

  Future<List<StressEntry>> fetchStress(String userId, DateTime from, DateTime to) async {
    final List<dynamic> data = jsonDecode(await _api.get('/stress/$userId',
        query: {'from': _date(from), 'to': _date(to)}));
    return [for (final e in data) StressEntry.fromJson(e as Map<String, dynamic>)];
  }

  Future<StressEntry> logStress(String userId, DateTime date, int level, {String? note}) async =>
      StressEntry.fromJson(jsonDecode(await _api.post('/stress/log', {
        'userId': userId,
        'date': _date(date),
        'level': level,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      })));

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Wall-clock time without offset, e.g. 2026-11-20T23:15:00.
  static String _localDateTime(DateTime d) =>
      '${_date(d)}T${_two(d.hour)}:${_two(d.minute)}:00';
}
