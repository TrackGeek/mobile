import '../models/api_exception.dart';
import '../models/person.dart';
import 'api_client.dart';

class PersonService {
  const PersonService(this._api);

  final ApiClient _api;

  Future<Person> person(
    String slug, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) => _fetch('person/$slug', language: language, cancelWhen: cancelWhen);

  Future<Person> mangaCast(
    String anilistId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) => _fetch(
    'manga/cast/$anilistId',
    language: language,
    cancelWhen: cancelWhen,
  );

  Future<Person> _fetch(
    String path, {
    required String language,
    Future<void>? cancelWhen,
  }) async {
    final json = await _api.getJson(
      path,
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return Person.fromJson(json['person'] as Map<String, dynamic>);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
