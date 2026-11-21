import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/view/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _utc(DateTime local) => local.toUtc().toIso8601String().replaceFirst('Z', '');

void main() {
  final today = DateUtils.dateOnly(DateTime.now());

  /// Fake tracking back-end. [failSleep] makes the sleep endpoint fail.
  MockClient backend({bool failSleep = false, List<Map<String, dynamic>>? posted}) {
    return MockClient((request) async {
      final path = request.url.path.replaceAll(ApiConfig.userId, 'u1');
      if (request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        posted?.add({'path': path, ...body});
        if (path == '/stress/log') {
          return http.Response(jsonEncode({...body, 'id': 'x'}), 200);
        }
        return http.Response('{}', 200);
      }
      if (path == '/users/u1') {
        return http.Response(
            jsonEncode({'id': 'u1', 'username': 'Amira Ben Salah', 'dailyWaterIntakeGoal': 2.5}), 200);
      }
      if (path == '/waterIntake/daily/u1') return http.Response('1.25', 200);
      if (path == '/waterIntake/range/u1') {
        return http.Response(
            jsonEncode([
              {'amount': 0.75, 'dateTime': _utc(today.add(const Duration(hours: 8)))},
              {'amount': 0.5, 'dateTime': _utc(today.add(const Duration(hours: 13)))},
            ]),
            200);
      }
      if (path == '/sleep/u1') {
        if (failSleep) return http.Response(jsonEncode({'detail': 'Sleep is down'}), 500);
        return http.Response(
            jsonEncode([
              {
                'date': _date(today),
                'bedTime': '${_date(today.subtract(const Duration(days: 1)))}T23:15:00',
                'wakeTime': '${_date(today)}T07:00:00',
                'durationMinutes': 465,
              }
            ]),
            200);
      }
      if (path == '/stress/u1') {
        return http.Response(
            jsonEncode([
              {'date': _date(today.subtract(const Duration(days: 2))), 'level': 2},
              {'date': _date(today), 'level': 4, 'note': 'exams'},
            ]),
            200);
      }
      return http.Response('not found', 404);
    });
  }

  Future<void> pumpHome(WidgetTester tester, MockClient client) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        hydrationService: HydrationService(client: client, baseUrl: 'http://api.test'),
        wellbeingService: WellbeingService(client: client, baseUrl: 'http://api.test'),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the user\'s real data', (tester) async {
    await pumpHome(tester, backend());

    expect(find.text('Amira Ben Salah'), findsOneWidget);
    expect(find.text('1.25 L'), findsOneWidget);
    expect(find.text('of 2.5 L · 50%'), findsOneWidget);
    expect(find.text('750 ml'), findsOneWidget); // before 9am
    expect(find.text('500 ml'), findsOneWidget); // 12pm - 3pm
    expect(find.text('7h 45m'), findsOneWidget);
    expect(find.text('11:15 pm – 7:00 am'), findsOneWidget);
    expect(find.text('Level 4 of 5'), findsOneWidget);
    expect(find.text('Update today'), findsOneWidget);
    // The old hardcoded values are gone.
    expect(find.text('4 Liters'), findsNothing);
    expect(find.text('8h 20m'), findsNothing);
  });

  testWidgets('a failing section shows an error without hiding the rest', (tester) async {
    await pumpHome(tester, backend(failSleep: true));

    expect(find.text('Sleep is down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Amira Ben Salah'), findsOneWidget);
    expect(find.text('1.25 L'), findsOneWidget);
    expect(find.text('Not logged'), findsOneWidget); // sleep card
  });

  testWidgets('logging stress posts today\'s level', (tester) async {
    final posted = <Map<String, dynamic>>[];
    await pumpHome(tester, backend(posted: posted));

    await tester.tap(find.text('Update today'));
    await tester.pumpAndSettle();
    expect(find.text('How stressed do you feel today?'), findsOneWidget);
    expect(find.text('exams'), findsOneWidget); // existing note prefilled

    await tester.tap(find.text('🙂')); // level 2, "Low"
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(posted, [
      {'path': '/stress/log', 'userId': ApiConfig.userId, 'date': _date(today), 'level': 2, 'note': 'exams'}
    ]);
    expect(find.text('Stress logged: Low'), findsOneWidget);
  });
}
