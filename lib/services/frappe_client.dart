import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Low-level Frappe / ERPNext REST client — no authentication required.
///
/// Set [baseUrl] to your ERPNext instance before using.
/// The app connects automatically on startup; no login screen needed.
class FrappeClient {
  FrappeClient._();

  // ── Base URL ───────────────────────────────────────────────────────────
  static const String baseUrl = 'https://najod.k.frappe.cloud';

  // ── API credentials ────────────────────────────────────────────────────
  // Regenerate: Login → My Settings → API Access → Generate Keys
  static const String _apiKey    = '0e961d779b3ae8e';
  static const String _apiSecret = 'de7aae198bb57bf';

  /// True once a successful request has been made.
  static bool _connected = false;
  static bool get isConnected => _connected;

  // ── Auth headers ──────────────────────────────────────────────────────
  static const Map<String, String> _headers = {
    'Authorization': 'token $_apiKey:$_apiSecret',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Connectivity check ────────────────────────────────────────────────
  /// Ping the Frappe instance. Returns true if reachable.
  static Future<bool> ping() async {
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

  // ── HTTP helpers ───────────────────────────────────────────────────────

  /// GET /api/resource/<doctype>?filters=...&fields=...
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

  /// GET /api/resource/<doctype>/<name>
  static Future<Map<String, dynamic>> getDoc({
    required String doctype,
    required String name,
  }) async {
    final uri = Uri.parse('$baseUrl/api/resource/$doctype/$name');
    return _get(uri);
  }

  /// GET /api/method/<method>
  static Future<Map<String, dynamic>> callMethod({
    required String method,
    Map<String, String>? params,
  }) async {
    final uri = Uri.parse('$baseUrl/api/method/$method')
        .replace(queryParameters: params);
    return _get(uri);
  }

  // ── Internal ──────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _get(Uri uri) async {
    debugPrint('[Frappe] GET $uri');
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 20));
    final result = _handleResponse(response);
    _connected = true;
    return result;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = err['message'] ?? err['exception'] ?? 'HTTP ${response.statusCode}';
      throw FrappeException(msg.toString(), statusCode: response.statusCode);
    } on FrappeException {
      rethrow;
    } catch (_) {
      throw FrappeException('HTTP ${response.statusCode}',
          statusCode: response.statusCode);
    }
  }
}

/// Typed exception for Frappe API errors.
class FrappeException implements Exception {
  final String message;
  final int? statusCode;
  const FrappeException(this.message, {this.statusCode});

  @override
  String toString() => 'FrappeException($statusCode): $message';
}
