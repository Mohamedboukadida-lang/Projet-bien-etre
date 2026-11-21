import 'dart:convert';

import 'package:fitnessapp/service/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('posts the conversation and context, returns the reply', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://ai.test/api/chat');
      sent = jsonDecode(request.body);
      return http.Response(
          jsonEncode({'reply': 'Drink a glass now 💧', 'model': 'm'}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final service = ChatService(client: client, baseUrl: 'http://ai.test');

    final reply = await service.send(
      const [ChatMessage.user('hi'), ChatMessage.assistant('hello'), ChatMessage.user('water?')],
      context: 'Water drunk today: 1 L',
    );

    expect(reply, 'Drink a glass now 💧');
    expect(sent['context'], 'Water drunk today: 1 L');
    expect(sent['messages'], [
      {'role': 'user', 'content': 'hi'},
      {'role': 'assistant', 'content': 'hello'},
      {'role': 'user', 'content': 'water?'},
    ]);
  });

  test('surfaces the server problem detail', () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({'status': 503, 'detail': 'set HF_TOKEN'}), 503));
    final service = ChatService(client: client, baseUrl: 'http://ai.test');

    expect(
      () => service.send(const [ChatMessage.user('hi')]),
      throwsA(isA<ChatException>()
          .having((e) => e.message, 'message', 'set HF_TOKEN')),
    );
  });

  test('explains when the back-end is unreachable', () async {
    final client = MockClient((_) async => throw http.ClientException('refused'));
    final service = ChatService(client: client, baseUrl: 'http://ai.test');

    expect(
      () => service.send(const [ChatMessage.user('hi')]),
      throwsA(isA<ChatException>()
          .having((e) => e.message, 'message', contains('Cannot reach'))),
    );
  });
}
