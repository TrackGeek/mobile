enum ApiFailure {
  network,
  timeout,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  http,
  invalidResponse,
}

class ApiException implements Exception {
  const ApiException(this.failure, {this.statusCode, this.serverCode});

  final ApiFailure failure;
  final int? statusCode;
  final String? serverCode;

  @override
  String toString() => 'ApiException(${failure.name}, status: $statusCode)';
}
