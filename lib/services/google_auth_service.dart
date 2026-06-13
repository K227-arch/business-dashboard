import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'frappe_client.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<String?> signIn() async {
    if (kIsWeb) {
      return _signInWeb();
    }
    return _signInMobile();
  }

  static Future<String?> _signInMobile() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      await _sendTokenToFrappe(auth.idToken!);
      return account.displayName ?? account.email;
    } catch (e) {
      debugPrint('[GoogleAuth] $e');
      rethrow;
    }
  }

  static Future<String?> _signInWeb() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      if (auth.idToken == null) {
        throw Exception('No ID token received from Google');
      }

      await _sendTokenToFrappe(auth.idToken!);
      return account.displayName ?? account.email;
    } catch (e) {
      debugPrint('[GoogleAuth] $e');
      rethrow;
    }
  }

  static Future<void> _sendTokenToFrappe(String idToken) async {
    await FrappeClient.callMethod(
      method: 'frappe.integrations.oauth2.login_via_google',
      params: {'id_token': idToken},
    );
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
