import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/api_client.dart';
import 'package:http/http.dart' as http;

/// A user account as stored by the tracking service.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.dailyGoal,
    this.heightCm,
    this.weightKg,
    this.dateOfBirth,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: (json['username'] as String?)?.trim() ?? '',
        dailyGoal: (json['dailyWaterIntakeGoal'] as num? ?? 0).toDouble(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        dateOfBirth: json['dateOfBirth'] == null
            ? null
            : DateTime.parse(json['dateOfBirth'] as String),
      );

  final String id;
  final String name;

  /// Litres.
  final double dailyGoal;

  /// Null until the user enters them.
  final double? heightCm;
  final double? weightKg;
  final DateTime? dateOfBirth;

  /// Age in whole years on [today], or null without a date of birth.
  int? ageOn(DateTime today) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final hadBirthday = today.month > dob.month ||
        (today.month == dob.month && today.day >= dob.day);
    return today.year - dob.year - (hadBirthday ? 0 : 1);
  }
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

  Future<AppUser> fetchUser(String userId) async =>
      AppUser.fromJson(jsonDecode(await _api.get('/users/$userId')));

  /// Updates the user's body data; null arguments are left unchanged.
  Future<AppUser> updateBody(String userId,
          {double? heightCm, double? weightKg, DateTime? dateOfBirth}) async =>
      AppUser.fromJson(jsonDecode(await _api.patch('/users/$userId', {
        if (heightCm != null) 'heightCm': heightCm,
        if (weightKg != null) 'weightKg': weightKg,
        if (dateOfBirth != null) 'dateOfBirth': _date(dateOfBirth),
      })));

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
