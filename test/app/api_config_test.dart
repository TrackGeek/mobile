import 'package:flutter_test/flutter_test.dart';
import 'package:trackgeek/app/api_config.dart';

void main() {
  test('preserves deployment prefix and encodes query exactly once', () {
    final config = ApiConfig(baseUrl: 'https://api.example.test/v1');

    final uri = config.endpoint('anime/search', {'query': 'ação & 漫画'});

    expect(uri.path, '/v1/anime/search');
    expect(uri.queryParameters, {'query': 'ação & 漫画'});
  });

  test('rejects missing URL, credentials and ambiguous base URLs', () {
    for (final url in [
      '',
      '/api',
      'http://api.example.test',
      'https://user:secret@api.example.test',
      'https://api.example.test?secret=value',
      'https://api.example.test#fragment',
    ]) {
      expect(() => ApiConfig(baseUrl: url), throwsArgumentError);
    }
  });

  test('endpoints cannot replace origin or escape deployment prefix', () {
    final config = ApiConfig(baseUrl: 'https://api.example.test/v1/');
    for (final path in [
      '',
      '/anime/search',
      '//other.test/anime/search',
      'https://other.test/anime/search',
      '../auth',
      '%2e%2e/auth',
      'anime/search?query=unexpected',
      'anime/search#fragment',
    ]) {
      expect(() => config.endpoint(path, {}), throwsArgumentError);
    }
  });
}
