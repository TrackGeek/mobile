import 'package:google_sign_in/google_sign_in.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

abstract class IdTokenSource {
  Future<String?> idToken();
}

class GoogleSignInSource implements IdTokenSource {
  GoogleSignInSource({required this.serverClientId});

  final String serverClientId;
  var _initialized = false;

  @override
  Future<String?> idToken() async {
    if (serverClientId.isEmpty) return null;
    if (!GoogleSignIn.instance.supportsAuthenticate()) return null;
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
      _initialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }
}

abstract class PasskeyAssertionSource {
  Future<Map<String, dynamic>> authenticate(Map<String, dynamic> options);

  Future<Map<String, dynamic>> register(Map<String, dynamic> options);
}

class PlatformPasskeySource implements PasskeyAssertionSource {
  PlatformPasskeySource() : _authenticator = PasskeyAuthenticator();

  final PasskeyAuthenticator _authenticator;

  @override
  Future<Map<String, dynamic>> authenticate(
    Map<String, dynamic> options,
  ) async {
    final normalized = <String, dynamic>{
      'challenge': options['challenge'],
      'rpId': options['rpId'] ?? (options['rp'] as Map?)?['id'],
      'timeout': options['timeout'],
      'userVerification': options['userVerification'],
      'allowCredentials': options['allowCredentials'],
      'extensions': options['extensions'],
    };
    final request = AuthenticateRequestType.fromJson(
      normalized,
      mediation: MediationType.Optional,
      preferImmediatelyAvailableCredentials: false,
    );
    final response = await _authenticator.authenticate(request);
    return response.toJson();
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> options) async {
    final request = RegisterRequestType.fromJson(options);
    final response = await _authenticator.register(request);
    final json = response.toJson()..remove('clientExtensionResults');
    return json;
  }
}
