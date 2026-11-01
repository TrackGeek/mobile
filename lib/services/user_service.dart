import '../models/api_exception.dart';
import '../models/discord_presence.dart';
import '../models/follow.dart';
import '../models/mission.dart';
import '../models/paginated_page.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class UserService {
  const UserService(this._api);

  final ApiClient _api;

  Future<UserProfile> userByUsername(
    String username, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'user/username/$username',
      language: language,
      cancelWhen: cancelWhen,
    );
    final user = res.json?['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return UserProfile.fromJson(user);
  }

  Future<bool> followStatus(
    String username, {
    String? language,
    Future<void>? cancelWhen,
  }) async => (await followStatusDetails(
    username,
    language: language,
    cancelWhen: cancelWhen,
  )).isFollowing;

  Future<FollowStatus> followStatusDetails(
    String username, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'user/follow-status/$username',
      language: language,
      cancelWhen: cancelWhen,
    );
    final status = res.json?['followStatus'];
    if (status is! Map<String, dynamic> || status['isFollowing'] is! bool) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return FollowStatus(
      isFollowing: status['isFollowing'] as bool,
      followsYou: status['followsYou'] == true,
    );
  }

  Future<void> follow(String userId, {String? language}) =>
      _api.requestJson('POST', 'user/follow/$userId', language: language);

  Future<void> unfollow(String userId, {String? language}) =>
      _api.requestJson('POST', 'user/unfollow/$userId', language: language);

  Future<PaginatedPage<FollowEntry>> followers(
    String userId, {
    int page = 1,
    int itemsPerPage = 10,
    String? language,
    Future<void>? cancelWhen,
  }) => _follows(
    'user/follower',
    'followers',
    userId,
    page: page,
    itemsPerPage: itemsPerPage,
    language: language,
    cancelWhen: cancelWhen,
  );

  Future<PaginatedPage<FollowEntry>> following(
    String userId, {
    int page = 1,
    int itemsPerPage = 10,
    String? language,
    Future<void>? cancelWhen,
  }) => _follows(
    'user/following',
    'following',
    userId,
    page: page,
    itemsPerPage: itemsPerPage,
    language: language,
    cancelWhen: cancelWhen,
  );

  Future<PaginatedPage<FollowEntry>> _follows(
    String path,
    String envelope,
    String userId, {
    required int page,
    required int itemsPerPage,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      path,
      query: {
        'userId': userId,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?[envelope] as Map<String, dynamic>,
        FollowEntry.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<UserMissionsSummary> missions(
    String userId, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'missions/user/$userId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final missions = res.json?['missions'];
    if (missions is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return UserMissionsSummary.fromJson(missions);
  }

  Future<ActivityCalendar> activityCalendar(
    String userId, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'activities/user/$userId/calendar',
      language: language,
      cancelWhen: cancelWhen,
    );
    final calendar = res.json?['activityCalendar'];
    if (calendar is! Map<String, dynamic> || calendar['items'] is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return ActivityCalendar(
      total: (calendar['total'] as num?)?.toInt() ?? 0,
      items: {
        for (final item in calendar['items'] as List)
          if (item is Map<String, dynamic> && item['date'] is String)
            item['date'] as String: (item['count'] as num?)?.toInt() ?? 0,
      },
    );
  }

  Future<void> createProfileLink({
    required String label,
    required String url,
  }) => _api.requestJson(
    'POST',
    'profile/link',
    body: {'label': label, 'url': url},
  );

  Future<void> updateProfileLink(
    String linkId, {
    required String label,
    required String url,
  }) => _api.requestJson(
    'PATCH',
    'profile/link/$linkId',
    body: {'label': label, 'url': url},
  );

  Future<void> deleteProfileLink(String linkId) =>
      _api.requestJson('DELETE', 'profile/link/$linkId');

  Future<void> reorderProfileLinks(List<String> linkIds) => _api.requestJson(
    'PATCH',
    'profile/links/order',
    body: {'linkIds': linkIds},
  );

  Future<void> addSetupPhoto(String url) =>
      _api.requestJson('POST', 'profile/setup/photo', body: {'url': url});

  Future<void> deleteSetupPhoto(String photoId) =>
      _api.requestJson('DELETE', 'profile/setup/photo/$photoId');

  Future<void> createSetupItem({
    required String type,
    String? name,
    String? brand,
    String? link,
  }) => _api.requestJson(
    'POST',
    'profile/setup/item',
    body: {'type': type, 'name': ?name, 'brand': ?brand, 'link': ?link},
  );

  Future<void> updateSetupItem(
    String itemId, {
    String? name,
    String? brand,
    String? link,
  }) => _api.requestJson(
    'PATCH',
    'profile/setup/item/$itemId',
    body: {'name': ?name, 'brand': ?brand, 'link': ?link},
  );

  Future<void> deleteSetupItem(String itemId) =>
      _api.requestJson('DELETE', 'profile/setup/item/$itemId');

  Future<void> reorderSetupItems(List<String> itemIds) => _api.requestJson(
    'PATCH',
    'profile/setup/items/order',
    body: {'itemIds': itemIds},
  );

  Future<DiscordPresence> discordPresence(
    String userId, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'discord/presence/$userId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final presence = res.json?['presence'];
    if (presence is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return DiscordPresence.fromJson(presence);
  }
}

class ActivityCalendar {
  const ActivityCalendar({required this.total, required this.items});

  final int total;
  final Map<String, int> items;
}
