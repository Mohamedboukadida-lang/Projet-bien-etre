import 'dart:convert';

import 'package:fitnessapp/config/api_config.dart';
import 'package:http/http.dart' as http;

/// A back-end call failed; [message] is ready to show to the user.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Minimal JSON-over-HTTP helper shared by the service clients.
class ApiClient {
  ApiClient({http.Client? client, required this.baseUrl, required this.serviceName})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Used in error messages, e.g. "hydration".
  final String serviceName;

  static const _jsonHeaders = {'Content-Type': 'application/json; charset=UTF-8'};

  /// GETs [path] and returns the body; throws [ApiException] unless HTTP 200.
  Future<String> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _send(() => _client.get(uri));
    return _check(response, path);
  }

  /// POSTs [body] as JSON to [path] and returns the response body; throws
  /// [ApiException] unless HTTP 200.
  Future<String> post(String path, Object body) async {
    final response = await _send(() => _client.post(Uri.parse('$baseUrl$path'),
        headers: _jsonHeaders, body: jsonEncode(body)));
    return _check(response, path);
  }

  String _check(http.Response response, String path) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode == 200) return body;
    String? detail;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) detail = decoded['detail'];
    } on FormatException {
      // Not JSON: fall back to the generic message.
    }
    throw ApiException(detail ??
        'The $serviceName service answered HTTP ${response.statusCode} for $path');
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(ApiConfig.timeout);
    } catch (_) {
      throw ApiException(
          'Cannot reach the $serviceName service at $baseUrl. Is the back-end running?');
    }
  }
}
