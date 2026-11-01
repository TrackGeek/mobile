import '../models/api_exception.dart';
import '../models/media_detail.dart';
import '../models/media_type.dart';
import 'api_client.dart';

class MediaDetailService {
  const MediaDetailService(this._api);

  final ApiClient _api;

  Future<MediaDetail> detail(
    MediaType type,
    String id, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    if (id.isEmpty) throw ArgumentError.value(id, 'id');
    final json = await _api.getJson(
      '${type.slug}/detail/$id',
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return MediaDetail.fromJson(
        type,
        json[type.detailEnvelope] as Map<String, dynamic>,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
