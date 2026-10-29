import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

import '../app/api_config.dart';
import '../models/api_exception.dart';

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.decoded,
    required this.headers,
  });

  final int statusCode;
  final Object? decoded;
  final Map<String, String> headers;

  Map<String, dynamic>? get json =>
      decoded is Map<String, dynamic> ? decoded as Map<String, dynamic> : null;

  List<dynamic>? get list => decoded is List ? decoded as List : null;

  String? get authToken => headers['set-auth-token'];
}

class ApiClient {
  ApiClient({
    required this._config,
    required this._client,
    this.timeout = const Duration(seconds: 20),
  }) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive');
    }
  }

  ApiConfig _config;
  final http.Client _client;
  final Duration timeout;

  String? bearerToken;

  void setBaseUrl(String baseUrl, {bool allowInsecure = false}) {
    _config = ApiConfig(baseUrl: baseUrl, allowInsecure: allowInsecure);
  }

  String get baseUrl => _config.baseUri.toString();

  Future<ApiResponse> requestJson(
    String method,
    String path, {
    Map<String, String> query = const {},
    Map<String, dynamic>? body,
    String language = 'en-US',
    Map<String, String> headers = const {},
    Future<void>? cancelWhen,
  }) async {
    final abort = Completer<void>();
    var finished = false;
    void cancel() {
      if (!finished && !abort.isCompleted) abort.complete();
    }

    if (cancelWhen != null) unawaited(cancelWhen.then((_) => cancel()));

    final request =
        http.AbortableRequest(
            method,
            _config.endpoint(path, query),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'X-TrackGeek-Version': '1.0.0',
            'X-TrackGeek-Language': language,
            if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
            ...headers,
          });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    try {
      final response = await _send(request).timeout(timeout);
      final result = ApiResponse(
        statusCode: response.statusCode,
        decoded: _tryDecode(response.bodyBytes),
        headers: response.headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _failureForStatus(response.statusCode),
          statusCode: response.statusCode,
          serverCode: _readServerCode(response.bodyBytes),
        );
      }
      return result;
    } on TimeoutException {
      cancel();
      throw const ApiException(ApiFailure.timeout);
    } on http.RequestAbortedException {
      throw const ApiException(ApiFailure.cancelled);
    } on http.ClientException {
      throw const ApiException(ApiFailure.network);
    } finally {
      finished = true;
    }
  }

  static Object? _tryDecode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
    String language = 'pt-PT',
    Future<void>? cancelWhen,
  }) async {
    final abort = Completer<void>();
    var finished = false;
    void cancel() {
      if (!finished && !abort.isCompleted) abort.complete();
    }

    if (cancelWhen != null) unawaited(cancelWhen.then((_) => cancel()));

    final request =
        http.AbortableRequest(
            'GET',
            _config.endpoint(path, query),
            abortTrigger: abort.future,
          )
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'X-TrackGeek-Version': '1.0.0',
            'X-TrackGeek-Language': language,
          });

    try {
      final response = await _send(request).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _failureForStatus(response.statusCode),
          statusCode: response.statusCode,
          serverCode: _readServerCode(response.bodyBytes),
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      return decoded;
    } on TimeoutException {
      cancel();
      throw const ApiException(ApiFailure.timeout);
    } on http.RequestAbortedException {
      throw const ApiException(ApiFailure.cancelled);
    } on http.ClientException {
      throw const ApiException(ApiFailure.network);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    } finally {
      finished = true;
    }
  }

  Future<ApiResponse> sendMultipart(
    String method,
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'file',
    String language = 'en-US',
    String? mimeType,
  }) async {
    final request =
        http.MultipartRequest(method, _config.endpoint(path, const {}))
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'X-TrackGeek-Version': '1.0.0',
            'X-TrackGeek-Language': language,
            if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              field,
              bytes,
              filename: filename,
              contentType: mimeType == null ? null : MediaType.parse(mimeType),
            ),
          );
    try {
      final response = await _send(request).timeout(timeout);
      final result = ApiResponse(
        statusCode: response.statusCode,
        decoded: _tryDecode(response.bodyBytes),
        headers: response.headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _failureForStatus(response.statusCode),
          statusCode: response.statusCode,
          serverCode: _readServerCode(response.bodyBytes),
        );
      }
      return result;
    } on TimeoutException {
      throw const ApiException(ApiFailure.timeout);
    } on http.ClientException {
      throw const ApiException(ApiFailure.network);
    }
  }

  Future<http.Response> _send(http.BaseRequest request) async =>
      http.Response.fromStream(await _client.send(request));

  void close() => _client.close();

  static ApiFailure _failureForStatus(int status) => switch (status) {
    401 => ApiFailure.unauthorized,
    403 => ApiFailure.forbidden,
    404 => ApiFailure.notFound,
    409 => ApiFailure.conflict,
    422 => ApiFailure.validation,
    429 => ApiFailure.rateLimited,
    >= 500 => ApiFailure.server,
    _ => ApiFailure.http,
  };

  static String? _readServerCode(List<int> bytes) {
    try {
      final body = jsonDecode(utf8.decode(bytes));
      final code = body is Map<String, dynamic> ? body['code'] : body;
      return code is String && RegExp(r'^[A-Z][A-Z0-9_]{0,99}$').hasMatch(code)
          ? code
          : null;
    } on FormatException {
      return null;
    }
  }
}
