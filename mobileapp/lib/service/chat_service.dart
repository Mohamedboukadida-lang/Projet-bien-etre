import 'dart:async';
import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:http/http.dart' as http;

/// One turn of the conversation. [role] is `user` or `assistant`.
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  const ChatMessage.user(this.content) : role = 'user';
  const ChatMessage.assistant(this.content) : role = 'assistant';

  final String role;
  final String content;

  bool get isUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatException implements Exception {
  const ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Talks to the AI service (`POST /api/chat`), which forwards the conversation
/// to a Hugging Face chat model.
class ChatService {
  ChatService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.aiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Sends the whole [history] (oldest first, ending with the user's message)
  /// and returns the assistant's reply. [context] gives the model facts about
  /// the user, such as today's water intake.
  Future<String> send(List<ChatMessage> history, {String? context}) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: const {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'messages': history.map((m) => m.toJson()).toList(),
              if (context != null && context.isNotEmpty) 'context': context,
            }),
          )
          .timeout(ApiConfig.chatTimeout);
    } on TimeoutException {
      throw const ChatException(
          'The coach is taking too long to answer. Please try again.');
    } catch (_) {
      throw ChatException(
          'Cannot reach the AI service at $_baseUrl. Is the back-end running?');
    }

    final body = _decode(response);
    if (response.statusCode == 200 && body?['reply'] is String) {
      return body!['reply'] as String;
    }
    final detail = body?['detail'];
    throw ChatException(detail is String && detail.isNotEmpty
        ? detail
        : 'The AI service answered with HTTP ${response.statusCode}.');
  }

  static Map<String, dynamic>? _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
