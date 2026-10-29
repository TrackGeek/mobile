import '../models/api_exception.dart';
import '../models/company.dart';
import '../models/media_type.dart';
import 'api_client.dart';

const companyEndpoints = {
  MediaType.movie: 'movie/company',
  MediaType.tv: 'tv/company',
  MediaType.anime: 'anime/company',
  MediaType.game: 'game/company',
};

class CompanyService {
  const CompanyService(this._api);

  final ApiClient _api;

  Future<Company> company(
    MediaType type,
    String id, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final endpoint = companyEndpoints[type];
    if (endpoint == null) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    final res = await _api.requestJson(
      'GET',
      '$endpoint/$id',
      language: language,
      cancelWhen: cancelWhen,
    );
    final company = res.json?['company'];
    if (company is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return Company.fromJson(company);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
