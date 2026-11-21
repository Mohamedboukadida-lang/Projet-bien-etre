import 'dart:convert';

import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/service/chat_service.dart';
import 'package:fitnessapp/view/chatbot/chatScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HydrationService hydration() => HydrationService(
        baseUrl: 'http://water.test',
        client: MockClient((request) async =>
            http.Response(request.url.path.endsWith('daily-goal') ? '2.5' : '1.0', 200)),
      );

  testWidgets('tapping a suggestion sends it and shows the coach reply',
      (tester) async {
    String? sentContext;
    final chat = ChatService(
      baseUrl: 'http://ai.test',
      client: MockClient((request) async {
        sentContext = jsonDecode(request.body)['context'];
        return http.Response(jsonEncode({'reply': 'About **2.5 L** today.'}), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(
        home: ChatScreen(chatService: chat, hydrationService: hydration())));
    expect(find.text("Hi! I'm your well-being coach."), findsOneWidget);

    await tester.tap(find.text('How much water should I drink today?'));
    await tester.pumpAndSettle();

    expect(find.text('How much water should I drink today?'), findsOneWidget);
    expect(find.text('About 2.5 L today.'), findsOneWidget);
    expect(sentContext, contains('1.00 L'));
    expect(sentContext, contains('2.50 L'));
  });

  testWidgets('shows the error and retries successfully', (tester) async {
    var calls = 0;
    final chat = ChatService(
      baseUrl: 'http://ai.test',
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response(jsonEncode({'detail': 'The AI model is busy'}), 503)
            : http.Response(jsonEncode({'reply': 'Here you go'}), 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(
        home: ChatScreen(chatService: chat, hydrationService: hydration())));
    await tester.enterText(find.byType(TextField), 'Sleep tips?');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('The AI model is busy'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Here you go'), findsOneWidget);
    expect(find.text('The AI model is busy'), findsNothing);
    expect(calls, 2);
  });
}
