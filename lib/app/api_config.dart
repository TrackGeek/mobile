class ApiConfig {
  ApiConfig({required String baseUrl, bool allowInsecure = false}) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        (uri.scheme != 'https' && !(allowInsecure && uri.scheme == 'http')) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'Expected an HTTPS API URL',
      );
    }
    baseUri = uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  factory ApiConfig.fromEnvironment() =>
      ApiConfig(baseUrl: const String.fromEnvironment('TRACKGEEK_API_URL'));

  late final Uri baseUri;

  Uri endpoint(String path, Map<String, String> query) {
    final relative = Uri.parse(path);
    if (path.isEmpty ||
        path.startsWith('/') ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasQuery ||
        relative.hasFragment ||
        relative.pathSegments.any(
          (segment) => segment == '..' || segment == '.',
        )) {
      throw ArgumentError.value(path, 'path', 'Expected a relative API path');
    }
    return baseUri
        .resolveUri(relative)
        .replace(queryParameters: query.isEmpty ? null : query);
  }
}
