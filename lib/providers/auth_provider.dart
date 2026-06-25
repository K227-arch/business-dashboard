import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/frappe_client.dart';

enum AuthStatus { uninitialized, needsUrl, needsLogin, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  String _baseUrl = '';
  String _userName = '';
  String? _error;
  String _lastEmail = '';

  AuthStatus get status => _status;
  String get baseUrl => _baseUrl;
  String get userName => _userName;
  String? get error => _error;
  String get lastEmail => _lastEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Session restore ────────────────────────────────────────────────────

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl   = prefs.getString('baseUrl');
    final savedToken = prefs.getString('apiToken');
    final savedUser  = prefs.getString('userName');
    final savedEmail = prefs.getString('lastEmail') ?? '';

    _lastEmail = savedEmail;

    // Always clear old session cookies — API token is the only auth method
    await prefs.remove('sessionCookie');

    if (savedUrl != null && savedToken != null && savedToken.isNotEmpty) {
      FrappeClient.restoreApiToken(savedToken, savedUrl);
      _baseUrl  = savedUrl;
      _userName = savedUser ?? '';

      // Verify token still works with a real API call, not just ping
      final ok = await _verifyApiToken();
      if (ok) {
        _status = AuthStatus.authenticated;
        _error  = null;
        notifyListeners();
        return;
      }
      // Token failed — send back to login
      _status = AuthStatus.needsLogin;
    } else if (savedUrl != null) {
      FrappeClient.setBaseUrl(savedUrl);
      _baseUrl = savedUrl;
      _status  = AuthStatus.needsLogin;
    } else {
      _status = AuthStatus.needsUrl;
    }
    notifyListeners();
  }

  /// Verify token by calling a protected endpoint that requires real auth
  Future<bool> _verifyApiToken() async {
    try {
      final result = await FrappeClient.callMethod(
        method: 'frappe.auth.get_logged_user',
      );
      final user = result['message']?.toString() ?? '';
      return user.isNotEmpty && user != 'Guest';
    } catch (_) {
      return false;
    }
  }

  // ── URL setup ──────────────────────────────────────────────────────────

  Future<void> setBaseUrl(String url) async {
    _error = null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _error = 'Please enter a URL';
      notifyListeners();
      return;
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      _error = 'URL must start with http:// or https://';
      notifyListeners();
      return;
    }

    FrappeClient.setBaseUrl(trimmed);
    _baseUrl = trimmed;
    _status  = AuthStatus.needsLogin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', trimmed);
    notifyListeners();
  }

  // ── API token login ────────────────────────────────────────────────────

  Future<void> loginWithApiToken({
    required String apiKey,
    required String apiSecret,
  }) async {
    _error  = null;
    _status = AuthStatus.needsLogin;
    notifyListeners();

    try {
      final name = await FrappeClient.loginWithApiToken(
        apiKey: apiKey.trim(),
        apiSecret: apiSecret.trim(),
      );
      _userName   = name;
      _status     = AuthStatus.authenticated;
      _error      = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('apiToken', '${apiKey.trim()}:${apiSecret.trim()}');
      await prefs.remove('sessionCookie'); // clear old cookie
    } on FrappeException catch (e) {
      _error  = e.message;
      _status = AuthStatus.needsLogin;
    } catch (e) {
      _error = e.toString().contains('TimeoutException')
          ? 'Connection timed out. Check your internet and try again.'
          : 'Connection failed: ${e.toString()}';
      _status = AuthStatus.needsLogin;
    }
    notifyListeners();
  }

  // ── Password login ──────────────────────────────────────────────────────

  Future<void> login({required String usr, required String pwd}) async {
    _error  = null;
    _status = AuthStatus.needsLogin;
    notifyListeners();

    try {
      // Login with email + password — session cookie is stored in FrappeClient
      await FrappeClient.login(usr: usr, pwd: pwd);
      _lastEmail = usr;

      // Get the logged-in user's full name
      try {
        final userRes = await FrappeClient.callMethod(
            method: 'frappe.auth.get_logged_user');
        _userName = userRes['message']?.toString() ?? usr;
      } catch (_) {
        _userName = usr;
      }

      _status = AuthStatus.authenticated;
      _error  = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _userName);
      await prefs.setString('lastEmail', usr);
      await prefs.setString('baseUrl', _baseUrl);
      // Store session cookie for restore on next app launch
      await prefs.setString('sessionCookie', FrappeClient.sessionCookie ?? '');
      await prefs.remove('apiToken');
    } on FrappeException catch (e) {
      _error  = e.message;
      _status = AuthStatus.needsLogin;
    } catch (e) {
      _error = e.toString().contains('TimeoutException')
          ? 'Connection timed out. Check your internet and try again.'
          : 'Connection failed: ${e.toString()}';
      _status = AuthStatus.needsLogin;
    }
    notifyListeners();
  }

  // ── Logout ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionCookie');
    await prefs.remove('apiToken');
    await prefs.remove('userName');
    _status     = AuthStatus.needsUrl;
    _baseUrl    = '';
    _userName   = '';
    _lastEmail  = '';
    _error      = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
