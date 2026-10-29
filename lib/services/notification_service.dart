import '../models/api_exception.dart';
import '../models/notification.dart';
import '../models/paginated_page.dart';
import 'api_client.dart';

class NotificationService {
  const NotificationService(this._api);

  final ApiClient _api;

  Future<PaginatedPage<AppNotification>> notifications({
    int page = 1,
    int itemsPerPage = 20,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'notifications',
      query: {'page': '$page', 'itemsPerPage': '$itemsPerPage'},
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['notifications'] as Map<String, dynamic>,
        AppNotification.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<int> unreadCount({String language = 'en-US'}) async {
    final res = await _api.requestJson(
      'GET',
      'notifications/unread/count',
      language: language,
    );
    final count = res.json?['count'];
    if (count is int && count >= 0) return count;
    throw const ApiException(ApiFailure.invalidResponse);
  }

  Future<void> markRead(String notificationId) =>
      _api.requestJson('POST', 'notifications/$notificationId/read');

  Future<void> markUnread(String notificationId) =>
      _api.requestJson('DELETE', 'notifications/$notificationId/read');

  Future<void> markAllRead() =>
      _api.requestJson('POST', 'notifications/read/all');

  Future<void> markAllUnread() =>
      _api.requestJson('DELETE', 'notifications/read/all');

  Future<void> delete(String notificationId) =>
      _api.requestJson('DELETE', 'notifications/$notificationId');

  Future<void> deleteAll() => _api.requestJson('DELETE', 'notifications/all');
}
