import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/external_sign_in.dart';
import '../services/notification_alerts.dart';
import '../services/widget_sync.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._auth, {this._google, this._passkeys});

  static const tokenKey = 'trackgeek.session.token';
  static const _userIdKey = 'trackgeek.session.userId';

  final AuthService _auth;
  final IdTokenSource? _google;
  final PasskeyAssertionSource? _passkeys;

  SessionUser? _user;
  bool _loading = true;
  bool _twoFactorPending = false;
  Object? _error;

  SessionUser? get user => _user;
  PasskeyAssertionSource? get passkeySource => _passkeys;
  AuthService get authService => _auth;
  bool get loading => _loading;
  bool get loggedIn => _user != null;
  bool get twoFactorPending => _twoFactorPending;
  Object? get error => _error;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token != null) {
      _auth.restoreToken(token);
      try {
        _user = await _auth.session();
      } catch (_) {
        _user = null;
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    try {
      final result = await _auth.signIn(email: email, password: password);
      if (result.requiresTwoFactor) {
        _twoFactorPending = true;
        notifyListeners();
        return false;
      }
      _user = result.user;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _error = null;
    try {
      final result = await _auth.signUp(
        name: name,
        email: email,
        password: password,
      );
      if (result.requiresTwoFactor) {
        _twoFactorPending = true;
        notifyListeners();
        return false;
      }
      _user = result.user;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyTwoFactor(String code, {bool backup = false}) async {
    _error = null;
    try {
      final result = await _auth.verifyTwoFactor(code: code, backup: backup);
      _user = result.user;
      _twoFactorPending = false;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    final user = await _auth.session();
    _user = user;
    notifyListeners();
  }

  Future<SocialAuthStart> startSocialSignIn(String provider) {
    _error = null;
    return _auth.socialAuthorizationUrl(provider);
  }

  String get apiBaseUrl => _auth.baseUrl;

  Future<bool> completeSocialSignIn(String sessionCookie) async {
    _error = null;
    try {
      final result = await _auth.applySessionCookie(sessionCookie);
      _user = result.user;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _error = null;
    final google = _google;
    if (google == null) {
      _error = StateError('google_sign_in not configured');
      notifyListeners();
      return false;
    }
    try {
      final token = await google.idToken();
      if (token == null || token.isEmpty) return false;
      final result = await _auth.signInWithIdToken('google', token: token);
      _user = result.user;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMagicLink(String email) async {
    _error = null;
    try {
      await _auth.sendMagicLink(email);
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithPasskey() async {
    _error = null;
    final passkeys = _passkeys;
    if (passkeys == null) {
      _error = StateError('passkeys not configured');
      notifyListeners();
      return false;
    }
    try {
      final options = await _auth.passkeyAuthenticateOptions();
      final assertion = await passkeys.authenticate(options);
      final result = await _auth.verifyPasskey(assertion);
      _user = result.user;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> handleAuthDeepLink(Uri uri) async {
    _error = null;
    try {
      final result = await _auth.applyAuthCallback(uri);
      if (result == null) return false;
      _user = result.user;
      _twoFactorPending = false;
      await _persist();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _user = null;
    _twoFactorPending = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(_userIdKey);
    unawaited(WidgetSync.refresh());
    unawaited(NotificationAlerts.disable());
    notifyListeners();
  }

  Future<void> _persist() async {
    final token = _auth.token;
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    final userId = _user?.id;
    if (userId != null) {
      await prefs.setString(_userIdKey, userId);
    }
    unawaited(WidgetSync.refresh());
    unawaited(NotificationAlerts.enable());
  }
}
