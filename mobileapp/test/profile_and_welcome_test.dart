import 'dart:convert';

import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/view/profile/user_profile.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

WellbeingService _service({String? name, bool down = false}) => WellbeingService(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        if (down) throw http.ClientException('refused');
        return http.Response(
            jsonEncode({'id': 'u1', 'username': name, 'dailyWaterIntakeGoal': 2.5}), 200);
      }),
    );

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('profile shows the user\'s name from the back-end', (tester) async {
    await _pump(tester, UserProfile(wellbeingService: _service(name: 'Amira Ben Salah')));
    expect(find.text('Amira Ben Salah'), findsOneWidget);
    expect(find.text('Mohamed Boukadida'), findsNothing);
  });

  testWidgets('profile says when the name cannot be loaded', (tester) async {
    await _pump(tester, UserProfile(wellbeingService: _service(down: true)));
    expect(find.text('Name unavailable'), findsOneWidget);
  });

  testWidgets('welcome greets the user by first name', (tester) async {
    await _pump(tester, WelcomeScreen(wellbeingService: _service(name: 'Amira  Ben Salah')));
    expect(find.text('Welcome, Amira'), findsOneWidget);
    expect(find.text('Welcome, Mohamed'), findsNothing);
  });

  testWidgets('welcome falls back to a generic greeting', (tester) async {
    await _pump(tester, WelcomeScreen(wellbeingService: _service(down: true)));
    expect(find.text('Welcome!'), findsOneWidget);

    await _pump(tester, WelcomeScreen(wellbeingService: _service(name: '')));
    expect(find.text('Welcome!'), findsOneWidget);
  });
}
