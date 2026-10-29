import '../models/api_exception.dart';
import '../models/oauth_app.dart';
import 'api_client.dart';

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.image,
    this.contentTypes = const [],
    this.about,
    this.color,
    this.avatarUrl,
    this.bannerUrl,
    this.language,
    this.timezone,
    this.watchRegion,
    this.avatarFrame,
    this.profileTitle,
    this.bannerEffect,
    this.twoFactorEnabled = false,
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final p = profile is Map<String, dynamic> ? profile : const {};
    final rawTypes = p['contentTypes'];
    return SessionUser(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      image: json['image'] as String?,
      contentTypes: rawTypes is List
          ? [for (final type in rawTypes) '$type']
          : const [],
      about: p['about'] as String?,
      color: p['color'] as String?,
      avatarUrl: p['avatarUrl'] as String?,
      bannerUrl: p['bannerUrl'] as String?,
      language: p['language'] as String?,
      timezone: p['timezone'] as String?,
      watchRegion: p['watchRegion'] as String?,
      avatarFrame: p['avatarFrame'] as String?,
      profileTitle: p['title'] as String?,
      bannerEffect: p['bannerEffect'] as String?,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String email;
  final String? username;
  final String? image;
  final List<String> contentTypes;
  final String? about;
  final String? color;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? language;
  final String? timezone;
  final String? watchRegion;
  final String? avatarFrame;
  final String? profileTitle;
  final String? bannerEffect;
  final bool twoFactorEnabled;
}

class AuthAccount {
  const AuthAccount({required this.providerId});

  final String providerId;
}

class PasskeyItem {
  const PasskeyItem({required this.id, this.name, this.createdAt});

  factory PasskeyItem.fromJson(Map<String, dynamic> json) => PasskeyItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String?,
    createdAt: json['createdAt'] as String?,
  );

  final String id;
  final String? name;
  final String? createdAt;
}

class TwoFactorSetup {
  const TwoFactorSetup({required this.totpUri, required this.backupCodes});

  final String totpUri;
  final List<String> backupCodes;
}

class AuthResult {
  const AuthResult({this.user, this.requiresTwoFactor = false});

  final SessionUser? user;
  final bool requiresTwoFactor;
}

class SocialAuthStart {
  const SocialAuthStart({
    required this.provider,
    required this.authorizationUrl,
    this.stateCookieName,
    this.stateCookieValue,
  });

  final String provider;
  final Uri authorizationUrl;
  final String? stateCookieName;
  final String? stateCookieValue;
}

class AuthService {
  AuthService(this._api);

  static const appCallbackUrl = 'trackgeek://auth/callback';
  static const webBaseUrl = 'https://trackgeek.net';
  static const sessionCookieName = 'better-auth.session_token';
  static const stateCookieName = 'better-auth.state';

  final ApiClient _api;

  final _cookies = <String, String>{};

  Map<String, String> get _cookieHeader => _cookies.isEmpty
      ? const {}
      : {'Cookie': _cookieString(), 'Origin': appCallbackUrl};

  String _cookieString() =>
      _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  void _storeCookies(Map<String, String> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final part in entry.value.split(',')) {
        final pair = part.trim().split(';').first.split('=');
        if (pair.length == 2 && pair[1].isNotEmpty && pair[1] != 'deleted') {
          _cookies[pair[0].trim()] = pair[1].trim();
        }
      }
    }
  }

  SessionUser? _userFrom(Map<String, dynamic>? json) {
    final user = json?['user'];
    return user is Map<String, dynamic> ? SessionUser.fromJson(user) : null;
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'auth/sign-in/email',
      body: {'email': email, 'password': password},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    final json = res.json;
    if (json == null) throw const ApiException(ApiFailure.invalidResponse);
    if (json['twoFactorRedirect'] == true) {
      return const AuthResult(requiresTwoFactor: true);
    }
    final user =
        _userFrom(json) ??
        _userFrom(
          json['session'] is Map<String, dynamic>
              ? json['session'] as Map<String, dynamic>
              : null,
        );
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'auth/sign-up/email',
      body: {'name': name, 'email': email, 'password': password},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    return signIn(email: email, password: password);
  }

  Future<AuthResult> verifyTwoFactor({
    required String code,
    bool backup = false,
  }) async {
    final res = await _api.requestJson(
      'POST',
      backup
          ? 'auth/two-factor/verify-backup-code'
          : 'auth/two-factor/verify-totp',
      body: {'code': code, 'trustDevice': true},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    final user = _userFrom(res.json);
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<SessionUser?> session() async {
    final res = await _api.requestJson(
      'GET',
      'auth/get-session',
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    return _userFrom(res.json);
  }

  Future<void> signOut() async {
    await _api.requestJson('POST', 'auth/sign-out', headers: _cookieHeader);
    _cookies.clear();
    _api.bearerToken = null;
  }

  Future<SocialAuthStart> socialAuthorizationUrl(String provider) async {
    final res = await _api.requestJson(
      'POST',
      'auth/sign-in/social',
      body: {
        'provider': provider,
        'callbackURL': appCallbackUrl,
        'errorCallbackURL': appCallbackUrl,
        'disableRedirect': true,
      },
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final url = res.json?['url'];
    if (url is! String || url.isEmpty) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return SocialAuthStart(
      provider: provider,
      authorizationUrl: Uri.parse(url),
      stateCookieName: stateCookieName,
      stateCookieValue: _cookies[stateCookieName],
    );
  }

  Future<AuthResult> signInWithIdToken(
    String provider, {
    required String token,
    String? accessToken,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'auth/sign-in/social',
      body: {
        'provider': provider,
        'callbackURL': appCallbackUrl,
        'idToken': {'token': token, 'accessToken': ?accessToken},
      },
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    final raw = res.json?['token'];
    if (raw is String && raw.isNotEmpty) _api.bearerToken = raw;
    final user = _userFrom(res.json);
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<AuthResult> applySessionCookie(String cookieValue) async {
    final decoded = Uri.decodeComponent(cookieValue);
    _cookies[sessionCookieName] = decoded;
    _api.bearerToken = decoded;
    final user = await session();
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<AuthResult?> applyAuthCallback(Uri uri) async {
    if (uri.scheme != 'trackgeek') return null;
    final raw = uri.queryParameters['cookie'];
    if (raw == null || raw.isEmpty) return null;
    for (final part in raw.split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) continue;
      final name = part.substring(0, eq).trim();
      final value = part.substring(eq + 1).trim();
      if (name.isEmpty || value.isEmpty || value == 'deleted') continue;
      _cookies[name] = value;
      if (name.contains('session_token')) _api.bearerToken = value;
    }
    final user = await session();
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<void> sendMagicLink(String email) async {
    final res = await _api.requestJson(
      'POST',
      'auth/sign-in/magic-link',
      body: {'email': email, 'callbackURL': appCallbackUrl},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.json?['status'] != true) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<Map<String, dynamic>> passkeyAuthenticateOptions() async {
    final res = await _api.requestJson(
      'GET',
      'auth/passkey/generate-authenticate-options',
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final json = res.json;
    if (json == null) throw const ApiException(ApiFailure.invalidResponse);
    return json;
  }

  Future<AuthResult> verifyPasskey(Map<String, dynamic> assertion) async {
    final res = await _api.requestJson(
      'POST',
      'auth/passkey/verify-authentication',
      body: {'response': assertion},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
    final user = _userFrom(res.json);
    if (user == null) throw const ApiException(ApiFailure.invalidResponse);
    return AuthResult(user: user);
  }

  Future<List<AuthAccount>> listAccounts() async {
    final res = await _api.requestJson(
      'GET',
      'auth/list-accounts',
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final items = res.list ?? res.json?['accounts'];
    if (items is! List) throw const ApiException(ApiFailure.invalidResponse);
    return [
      for (final item in items)
        if (item is Map<String, dynamic>)
          AuthAccount(providerId: item['providerId'] as String? ?? ''),
    ];
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'auth/change-password',
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'revokeOtherSessions': true,
      },
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.requestJson(
      'POST',
      'auth/request-password-reset',
      body: {'email': email, 'redirectTo': '$webBaseUrl/reset-password'},
      headers: _cookieHeader,
    );
  }

  Future<void> deleteUser() async {
    await _api.requestJson(
      'POST',
      'auth/delete-user',
      body: {'callbackURL': '$webBaseUrl/account-deleted'},
      headers: _cookieHeader,
    );
  }

  Future<TwoFactorSetup> twoFactorEnable(String password) async {
    final res = await _api.requestJson(
      'POST',
      'auth/two-factor/enable',
      body: {'password': password},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final json = res.json;
    final totpUri = json?['totpURI'];
    if (totpUri is! String) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return TwoFactorSetup(
      totpUri: totpUri,
      backupCodes: [
        for (final code in json?['backupCodes'] as List? ?? const []) '$code',
      ],
    );
  }

  Future<void> twoFactorVerifyTotp(String code) async {
    final res = await _api.requestJson(
      'POST',
      'auth/two-factor/verify-totp',
      body: {'code': code},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    if (res.authToken != null) _api.bearerToken = res.authToken;
  }

  Future<void> twoFactorDisable(String password) async {
    await _api.requestJson(
      'POST',
      'auth/two-factor/disable',
      body: {'password': password},
      headers: _cookieHeader,
    );
  }

  Future<List<String>> twoFactorBackupCodes(String password) async {
    final res = await _api.requestJson(
      'POST',
      'auth/two-factor/generate-backup-codes',
      body: {'password': password},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final codes = res.json?['backupCodes'];
    if (codes is! List) throw const ApiException(ApiFailure.invalidResponse);
    return [for (final code in codes) '$code'];
  }

  Future<List<PasskeyItem>> listPasskeys() async {
    final res = await _api.requestJson(
      'GET',
      'auth/passkey/list-user-passkeys',
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final items = res.list ?? res.json?['passkeys'];
    if (items is! List) throw const ApiException(ApiFailure.invalidResponse);
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) PasskeyItem.fromJson(item),
    ];
  }

  Future<Map<String, dynamic>> passkeyRegisterOptions(String? name) async {
    final res = await _api.requestJson(
      'GET',
      'auth/passkey/generate-register-options',
      query: name == null || name.isEmpty ? const {} : {'name': name},
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final json = res.json;
    if (json == null) throw const ApiException(ApiFailure.invalidResponse);
    return json;
  }

  Future<void> passkeyVerifyRegistration(
    Map<String, dynamic> response,
    String? name,
  ) async {
    await _api.requestJson(
      'POST',
      'auth/passkey/verify-registration',
      body: {'response': response, 'name': ?name},
      headers: _cookieHeader,
    );
  }

  Future<void> deletePasskey(String id) async {
    await _api.requestJson(
      'POST',
      'auth/passkey/delete-passkey',
      body: {'id': id},
      headers: _cookieHeader,
    );
  }

  Future<List<OAuthClientInfo>> oauthClients() async {
    final res = await _api.requestJson(
      'GET',
      'auth/oauth2/get-clients',
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final items = res.list ?? res.json?['clients'];
    if (items is! List) throw const ApiException(ApiFailure.invalidResponse);
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) OAuthClientInfo.fromJson(item),
    ];
  }

  Future<OAuthClientCredentials> createOAuthClient({
    required String name,
    required List<String> redirectUris,
    required bool confidential,
    required List<String> scopes,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'auth/oauth2/create-client',
      body: {
        'client_name': name,
        'redirect_uris': redirectUris,
        'token_endpoint_auth_method': confidential
            ? 'client_secret_basic'
            : 'none',
        'grant_types': ['authorization_code', 'refresh_token'],
        'response_types': ['code'],
        'scope': scopes.join(' '),
      },
      headers: _cookieHeader,
    );
    _storeCookies(res.headers);
    final clientId = res.json?['client_id'];
    if (clientId is! String) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return OAuthClientCredentials(
      clientId: clientId,
      clientSecret: res.json?['client_secret'] as String?,
    );
  }

  Future<void> deleteOAuthClient(String clientId) async {
    await _api.requestJson(
      'POST',
      'auth/oauth2/delete-client',
      body: {'client_id': clientId},
      headers: _cookieHeader,
    );
  }

  String? cookieValue(String name) => _cookies[name];

  String get baseUrl => _api.baseUrl;

  void restoreToken(String token) => _api.bearerToken = token;

  String? get token => _api.bearerToken;
}
