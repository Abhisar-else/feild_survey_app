import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? _getDefaultBaseUrl();

  final http.Client _client;
  final String baseUrl;

  static String _getDefaultBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    }
    
    // For mobile emulators
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://127.0.0.1:3000';
  }

  Future<Map<String, dynamic>> get(String path, {String? token}) {
    return _send('GET', path, token: token);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) {
    return _send('POST', path, token: token, body: body);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) {
    return _send('PUT', path, token: token, body: body);
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return _send('DELETE', path, token: token);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    
    if (kDebugMode) {
      print('🚀 API Request: $method ${uri.toString()}');
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final requestBody = body == null ? null : jsonEncode(body);
      final Future<http.Response> request = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: requestBody),
        'PUT' => _client.put(uri, headers: headers, body: requestBody),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ApiException('Unsupported request method: $method'),
      };
      final response = await request.timeout(const Duration(seconds: 30));

      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          payload['message'] as String? ?? 'Request failed with status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      return payload;
    } on TimeoutException {
      throw const ApiException('The server did not respond in time.');
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    } on http.ClientException catch (error) {
      throw ApiException('Could not reach the server: ${error.message}');
    }
  }

  void close() => _client.close();
}
