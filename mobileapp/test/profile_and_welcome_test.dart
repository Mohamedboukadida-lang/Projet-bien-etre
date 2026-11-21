import 'dart:convert';

import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/view/profile/user_profile.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

WellbeingService _service(
        {String? name, bool down = false, Map<String, dynamic> body = const {}, List<Map>? patched}) =>
    WellbeingService(
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        if (down) throw http.ClientException('refused');
        final user = {'id': 'u1', 'username': name, 'dailyWaterIntakeGoal': 2.5, ...body};
        if (request.method == 'PATCH') {
          final changes = jsonDecode(request.body) as Map<String, dynamic>;
          patched?.add(changes);
          return http.Response(jsonEncode({...user, ...changes}), 200);
        }
        return http.Response(jsonEncode(user), 200);
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
  test('age counts whole years and changes on the birthday', () {
    final user = AppUser(id: 'u1', name: 'A', dailyGoal: 2, dateOfBirth: DateTime(2000, 6, 15));
    expect(user.ageOn(DateTime(2026, 6, 14)), 25);
    expect(user.ageOn(DateTime(2026, 6, 15)), 26);
    expect(const AppUser(id: 'u1', name: 'A', dailyGoal: 2).ageOn(DateTime(2026)), isNull);
  });

  testWidgets('profile shows the stored height, weight and age', (tester) async {
    final dob = DateTime.now().subtract(const Duration(days: 365 * 30 + 20));
    await _pump(tester, UserProfile(wellbeingService: _service(name: 'Amira', body: {
      'heightCm': 168.0,
      'weightKg': 61.5,
      'dateOfBirth': '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
    })));
    expect(find.text('168cm'), findsOneWidget);
    expect(find.text('61.5kg'), findsOneWidget);
    expect(find.text('30yo'), findsOneWidget);
    expect(find.text('180cm'), findsNothing);
  });

  testWidgets('profile shows dashes until body data is entered', (tester) async {
    await _pump(tester, UserProfile(wellbeingService: _service(name: 'Amira')));
    expect(find.text('–'), findsNWidgets(3));
  });

  testWidgets('editing body data saves it and updates the cells', (tester) async {
    final patched = <Map>[];
    await _pump(tester, UserProfile(wellbeingService: _service(name: 'Amira', patched: patched)));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('height-field')), '20');
    await tester.pump();
    expect(find.text('Between 50 and 260 cm'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('height-field')), '172,5');
    await tester.enterText(find.byKey(const Key('weight-field')), '64');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(patched, [{'heightCm': 172.5, 'weightKg': 64.0}]);
    expect(find.text('172.5cm'), findsOneWidget);
    expect(find.text('64kg'), findsOneWidget);
    expect(find.text('Profile updated'), findsOneWidget);
  });

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
