import '../models/cosmetic.dart';
import '../models/oauth_app.dart';
import '../models/watch_link.dart';
import 'api_client.dart';

class NotificationPreferences {
  const NotificationPreferences(this.values);

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences({
        for (final key in keys) key: json[key] as bool? ?? true,
      });

  static const keys = [
    'comment',
    'reaction',
    'newEpisode',
    'newChapter',
    'gameRelease',
    'sequelAdded',
    'reopenedCompleted',
    'levelUp',
    'mission',
  ];

  final Map<String, bool> values;

  bool operator [](String key) => values[key] ?? true;
}

class SettingsService {
  const SettingsService(this._api);

  final ApiClient _api;

  Future<void> updateUser({required String name, required String username}) =>
      _api.requestJson(
        'PATCH',
        'user',
        body: {'name': name, 'username': username},
      );

  Future<void> updateProfile(Map<String, Object?> fields) =>
      _api.requestJson('PATCH', 'profile', body: fields);

  Future<void> uploadAvatar(List<int> bytes, String filename, String? mime) =>
      _api.sendMultipart(
        'PATCH',
        'profile/avatar',
        bytes: bytes,
        filename: filename,
        mimeType: mime,
      );

  Future<void> deleteAvatar() => _api.requestJson('DELETE', 'profile/avatar');

  Future<void> uploadBanner(List<int> bytes, String filename, String? mime) =>
      _api.sendMultipart(
        'PATCH',
        'profile/banner',
        bytes: bytes,
        filename: filename,
        mimeType: mime,
      );

  Future<void> deleteBanner() => _api.requestJson('DELETE', 'profile/banner');

  Future<CosmeticsBundle> cosmetics() async {
    final res = await _api.requestJson('GET', 'cosmetics');
    final json = res.json;
    if (json == null) {
      return const CosmeticsBundle(
        profileColors: [],
        avatarFrames: [],
        profileTitles: [],
        bannerEffects: [],
      );
    }
    return CosmeticsBundle.fromJson(json);
  }

  Future<List<WatchLink>> watchLinks() async {
    final res = await _api.requestJson('GET', 'profile/watch-links');
    return [
      for (final item in res.json?['watchLinks'] as List? ?? const [])
        if (item is Map<String, dynamic>) WatchLink.fromJson(item),
    ];
  }

  Future<WatchLink> createWatchLink({
    required String label,
    required String url,
    required List<String> contentTypes,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'profile/watch-link',
      body: {'label': label, 'url': url, 'contentTypes': contentTypes},
    );
    return WatchLink.fromJson(res.json?['watchLink'] as Map<String, dynamic>);
  }

  Future<WatchLink> updateWatchLink(
    String linkId,
    Map<String, Object?> fields,
  ) async {
    final res = await _api.requestJson(
      'PATCH',
      'profile/watch-link/$linkId',
      body: fields,
    );
    return WatchLink.fromJson(res.json?['watchLink'] as Map<String, dynamic>);
  }

  Future<void> deleteWatchLink(String linkId) =>
      _api.requestJson('DELETE', 'profile/watch-link/$linkId');

  Future<void> reorderWatchLinks(List<String> linkIds) => _api.requestJson(
    'PATCH',
    'profile/watch-links/order',
    body: {'linkIds': linkIds},
  );

  Future<NotificationPreferences> notificationPreferences() async {
    final res = await _api.requestJson('GET', 'notifications/preferences');
    final prefs = res.json?['preferences'];
    return NotificationPreferences.fromJson(
      prefs is Map<String, dynamic> ? prefs : const {},
    );
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    Map<String, bool> fields,
  ) async {
    final res = await _api.requestJson(
      'PATCH',
      'notifications/preferences',
      body: fields,
    );
    final prefs = res.json?['preferences'];
    return NotificationPreferences.fromJson(
      prefs is Map<String, dynamic> ? prefs : const {},
    );
  }

  Future<List<AuthorizedOAuthApp>> authorizedApps() async {
    final res = await _api.requestJson('GET', 'integrations/apps');
    return [
      for (final item in res.json?['apps'] as List? ?? const [])
        if (item is Map<String, dynamic>) AuthorizedOAuthApp.fromJson(item),
    ];
  }

  Future<void> revokeAuthorizedApp(String clientId) => _api.requestJson(
    'DELETE',
    'integrations/apps/${Uri.encodeComponent(clientId)}',
  );
}
