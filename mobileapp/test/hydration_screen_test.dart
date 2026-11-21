import 'dart:convert';

import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/view/hydration-tracker/HydrationScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('loads data from the service and logs a drink', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    var today = 1.0;
    final logged = <double>[];
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/daily-goal')) return http.Response('2.0', 200);
      if (path.contains('/waterIntake/daily/')) return http.Response('$today', 200);
      if (path.contains('/weeklySummary/')) {
        return http.Response(
            jsonEncode({
              '2026-11-16': 2.0, '2026-11-17': 0.0, '2026-11-18': today,
              '2026-11-19': 0.0, '2026-11-20': 0.0, '2026-11-21': 0.0, '2026-11-22': 0.0,
            }),
            200);
      }
      if (path.endsWith('/logIntake')) {
        final body = jsonDecode(request.body);
        expect(body['date'], HydrationService.localDate(DateTime.now()));
        final sentAt = DateTime.parse('${body['dateTime']}Z');
        expect(DateTime.now().difference(sentAt).inMinutes.abs(), lessThan(2));
        final amount = (body['amount'] as num).toDouble();
        logged.add(amount);
        today += amount;
        return http.Response('{}', 200);
      }
      return http.Response('not found', 404);
    });

    await tester.pumpWidget(MaterialApp(
        home: HydrationScreen(
            service: HydrationService(client: client, baseUrl: 'http://water.test'))));
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1.00 L'), findsOneWidget);
    expect(find.text('2.00 L'), findsOneWidget);

    await tester.tap(find.text('500 ml'));
    await tester.pumpAndSettle();

    expect(logged, [0.5]);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('+500 ml logged'), findsOneWidget);
  });

  testWidgets('shows a retryable error when the service is down', (tester) async {
    final client = MockClient((_) async => throw http.ClientException('refused'));

    await tester.pumpWidget(MaterialApp(
        home: HydrationScreen(
            service: HydrationService(client: client, baseUrl: 'http://water.test'))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cannot reach the hydration service'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
