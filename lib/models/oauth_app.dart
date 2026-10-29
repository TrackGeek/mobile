class AuthorizedOAuthApp {
  const AuthorizedOAuthApp({
    required this.id,
    required this.clientId,
    this.name,
    required this.scopes,
  });

  factory AuthorizedOAuthApp.fromJson(Map<String, dynamic> json) =>
      AuthorizedOAuthApp(
        id: json['id'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        name: json['name'] as String?,
        scopes: [
          for (final scope in json['scopes'] as List? ?? const []) '$scope',
        ],
      );

  final String id;
  final String clientId;
  final String? name;
  final List<String> scopes;
}

class OAuthClientInfo {
  const OAuthClientInfo({required this.clientId, this.clientName});

  factory OAuthClientInfo.fromJson(Map<String, dynamic> json) =>
      OAuthClientInfo(
        clientId: json['client_id'] as String? ?? '',
        clientName: json['client_name'] as String?,
      );

  final String clientId;
  final String? clientName;
}

class OAuthClientCredentials {
  const OAuthClientCredentials({required this.clientId, this.clientSecret});

  final String clientId;
  final String? clientSecret;
}
