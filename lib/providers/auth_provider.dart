import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/frappe_client.dart';
import '../services/google_auth_service.dart';

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

  Future<void> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('baseUrl');
    final savedCookie = prefs.getString('sessionCookie');
    final savedUser = prefs.getString('userName');
    final savedEmail = prefs.getString('lastEmail') ?? '';

    _lastEmail = savedEmail;

    if (savedUrl != null && savedCookie != null && savedCookie.isNotEmpty) {
      FrappeClient.restoreSession(savedCookie, savedUrl);
      _baseUrl = savedUrl;
      _userName = savedUser ?? '';

      final ok = await FrappeClient.ping();
      if (ok) {
        _status = AuthStatus.authenticated;
        _error = null;
        notifyListeners();
        return;
      }
    }

    if (savedUrl != null) {
      FrappeClient.setBaseUrl(savedUrl);
      _baseUrl = savedUrl;
      _status = AuthStatus.needsLogin;
    } else {
      _status = AuthStatus.needsUrl;
    }
    notifyListeners();
  }

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
    _status = AuthStatus.needsLogin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', trimmed);
    notifyListeners();
  }

  Future<void> login({required String usr, required String pwd}) async {
    _error = null;
    _status = AuthStatus.needsLogin;
    notifyListeners();

    try {
      final name = await FrappeClient.login(usr: usr, pwd: pwd);
      _userName = name;
      _lastEmail = usr;
      _status = AuthStatus.authenticated;
      _error = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      await prefs.setString('lastEmail', usr);
      final cookie = FrappeClient.sessionCookie;
      if (cookie != null) {
        await prefs.setString('sessionCookie', cookie);
      }
    } on FrappeException catch (e) {
      _error = e.message;
      _status = AuthStatus.needsLogin;
    } catch (e) {
      _error = 'Connection failed: ${e.toString()}';
      _status = AuthStatus.needsLogin;
    }
    notifyListeners();
  }

  Future<void> googleLogin() async {
    _error = null;
    notifyListeners();

    try {
      final name = await GoogleAuthService.signIn();
      if (name != null) {
        _userName = name;
        _status = AuthStatus.authenticated;
        _error = null;
      }
    } on FrappeException catch (e) {
      _error = e.message;
      _status = AuthStatus.needsLogin;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('sign_in_failed') || msg.contains('network_error')) {
        _error = 'Google sign-in failed. Check your connection and try again.';
      } else if (msg.contains('No ID token')) {
        _error = 'Could not get Google credentials. Try again.';
      } else if (msg.contains('PlatformException')) {
        _error =
            'Google Sign-In is not configured. Use email/password instead.';
      } else {
        _error = 'Google sign-in failed: ${e.toString()}';
      }
      _status = AuthStatus.needsLogin;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionCookie');
    await prefs.remove('userName');
    _status = AuthStatus.needsUrl;
    _baseUrl = '';
    _userName = '';
    _lastEmail = '';
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
