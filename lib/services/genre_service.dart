import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/media_type.dart';

class GenreService {
  GenreService({http.Client? client, this._baseUrl = _defaultBase})
    : _client = client ?? http.Client();

  static const _defaultBase = 'https://api.tenrai.org/v1';

  final http.Client _client;
  final String _baseUrl;

  static bool hasRemoteGenres(MediaType type) =>
      type == MediaType.anime || type == MediaType.manga;

  Future<List<String>?> genres(MediaType type) async {
    if (!hasRemoteGenres(type)) return null;
    try {
      final res = await _client.get(Uri.parse('$_baseUrl/genres/${type.slug}'));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
      if (data is! List) return null;
      return [
        for (final genre in data)
          if (genre is Map<String, dynamic> && genre['name'] is String)
            genre['name'] as String,
      ];
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
