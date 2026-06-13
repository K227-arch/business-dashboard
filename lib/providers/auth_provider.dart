import 'package:flutter/foundation.dart';
import '../services/frappe_client.dart';
import '../services/google_auth_service.dart';

enum AuthStatus { uninitialized, needsUrl, needsLogin, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.needsUrl;
  String _baseUrl = '';
  String _userName = '';
  String? _error;

  AuthStatus get status => _status;
  String get baseUrl => _baseUrl;
  String get userName => _userName;
  String? get error => _error;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

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
    notifyListeners();
  }

  Future<void> login({required String usr, required String pwd}) async {
    _error = null;
    _status = AuthStatus.needsLogin;
    notifyListeners();

    try {
      final name = await FrappeClient.login(usr: usr, pwd: pwd);
      _userName = name;
      _status = AuthStatus.authenticated;
      _error = null;
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

  void logout() {
    _status = AuthStatus.needsUrl;
    _baseUrl = '';
    _userName = '';
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
