import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FrappeClient {
  FrappeClient._();

  static String baseUrl = '';

  static String? _sessionCookie;
  static bool _connected = false;
  static bool get isConnected => _connected;

  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _connected = false;
    _sessionCookie = null;
  }

  static Future<String> login({
    required String usr,
    required String pwd,
  }) async {
    final uri = Uri.parse('$baseUrl/api/method/login');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'usr': usr, 'pwd': pwd},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body) as Map;
        throw FrappeException(
          err['message']?.toString() ?? 'Login failed',
          statusCode: response.statusCode,
        );
      } on FrappeException {
        rethrow;
      } catch (_) {
        throw FrappeException('Login failed (HTTP ${response.statusCode})',
            statusCode: response.statusCode);
      }
    }

    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      _sessionCookie = setCookie.split(';').first;
    }

    _connected = true;
    final body = jsonDecode(response.body) as Map;
    return body['message']?.toString() ?? 'User';
  }

  static Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_sessionCookie != null) {
      h['Cookie'] = _sessionCookie!;
      h['X-Frappe-CSRF-Token'] = _csrfFromCookie();
    }
    return h;
  }

  static String _csrfFromCookie() {
    if (_sessionCookie == null) return '';
    for (final part in _sessionCookie!.split(';')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('csrf_token=')) {
        return trimmed.substring('csrf_token='.length);
      }
    }
    return '';
  }

  static Future<bool> ping() async {
    if (kIsWeb) {
      _connected = true;
      return true;
    }
    try {
      final uri = Uri.parse('$baseUrl/api/method/frappe.ping');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      _connected = response.statusCode == 200;
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  static Future<Map<String, dynamic>> getList({
    required String doctype,
    List<String>? fields,
    List<dynamic>? filters,
    int limit = 50,
    int limitStart = 0,
    String? orderBy,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'limit_start': limitStart.toString(),
      if (fields != null) 'fields': jsonEncode(fields),
      if (filters != null) 'filters': jsonEncode(filters),
      if (orderBy != null) 'order_by': orderBy,
    };
    final uri = Uri.parse('$baseUrl/api/resource/$doctype')
        .replace(queryParameters: params);
    return _get(uri);
  }

  static Future<Map<String, dynamic>> getDoc({
    required String doctype,
    required String name,
  }) async {
    final uri = Uri.parse('$baseUrl/api/resource/$doctype/$name');
    return _get(uri);
  }

  static Future<Map<String, dynamic>> callMethod({
    required String method,
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$baseUrl/api/method/$method')
        .replace(queryParameters: params);
    return _get(uri);
  }

  static Future<Map<String, dynamic>> callMethodPost({
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl/api/method/$method');
    debugPrint('[Frappe] POST $uri');
    try {
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      if (kIsWeb) {
        debugPrint('[Frappe] Web CORS/network error — $e');
        return {'data': [], 'message': null};
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _get(Uri uri) async {
    debugPrint('[Frappe] GET $uri');
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 20));
      final result = _handleResponse(response);
      _connected = true;
      return result;
    } on http.ClientException catch (e) {
      if (kIsWeb) {
        debugPrint('[Frappe] Web CORS/network error — returning empty: $e');
        return {'data': [], 'message': null};
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      final msg =
          err['message'] ?? err['exception'] ?? 'HTTP ${response.statusCode}';
      throw FrappeException(msg.toString(), statusCode: response.statusCode);
    } on FrappeException {
      rethrow;
    } catch (_) {
      throw FrappeException('HTTP ${response.statusCode}',
          statusCode: response.statusCode);
    }
  }
}

class FrappeException implements Exception {
  final String message;
  final int? statusCode;
  const FrappeException(this.message, {this.statusCode});

  @override
  String toString() => 'FrappeException($statusCode): $message';
}
