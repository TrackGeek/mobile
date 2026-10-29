import 'follow.dart';
import 'media_type.dart';

class UserListItem {
  const UserListItem({required this.id, required this.media});

  final String id;
  final Map<String, dynamic> media;

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    const keys = ['anime', 'manga', 'tvShow', 'movie', 'game', 'book'];
    Map<String, dynamic> media = const {};
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        media = value;
        break;
      }
    }
    return UserListItem(id: '${json['id']}', media: media);
  }
}

class UserList {
  const UserList({
    required this.id,
    required this.name,
    required this.type,
    required this.user,
    this.description,
    this.itemCount = 0,
    this.previewItems = const [],
  });

  final String id;
  final String name;
  final String type;
  final FollowUser user;
  final String? description;
  final int itemCount;
  final List<UserListItem> previewItems;

  factory UserList.fromJson(Map<String, dynamic> json) => UserList(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    type: '${json['type'] ?? ''}',
    user: json['user'] is Map<String, dynamic>
        ? FollowUser.fromJson(json['user'] as Map<String, dynamic>)
        : const FollowUser(id: '', name: '', username: ''),
    description: json['description'] as String?,
    itemCount: json['_count'] is Map<String, dynamic>
        ? ((json['_count'] as Map)['listItems'] as num?)?.toInt() ?? 0
        : 0,
    previewItems: [
      for (final item in json['listItems'] as List? ?? const [])
        if (item is Map<String, dynamic>) UserListItem.fromJson(item),
    ],
  );

  MediaType? get mediaType => switch (type) {
    'TVShow' => MediaType.tv,
    'Movie' => MediaType.movie,
    'Anime' => MediaType.anime,
    'Manga' => MediaType.manga,
    'Game' => MediaType.game,
    'Book' => MediaType.book,
    _ => null,
  };
}

class UserListGroup {
  const UserListGroup({
    required this.key,
    required this.name,
    required this.lists,
  });

  final String key;
  final String name;
  final List<UserList> lists;

  factory UserListGroup.fromJson(Map<String, dynamic> json) => UserListGroup(
    key: '${json['key']}',
    name: '${json['name'] ?? ''}',
    lists: [
      for (final list in json['lists'] as List? ?? const [])
        if (list is Map<String, dynamic>) UserList.fromJson(list),
    ],
  );
}

class ListItemLink {
  const ListItemLink({
    required this.type,
    required this.slug,
    required this.title,
    required this.image,
  });

  final MediaType type;
  final String slug;
  final String title;
  final String image;
}

ListItemLink? listItemToLink(UserListItem item, String listType) {
  final media = item.media;
  String? slug(String key) => media[key] == null ? null : '${media[key]}';
  final type = switch (listType) {
    'TVShow' => MediaType.tv,
    'Movie' => MediaType.movie,
    'Anime' => MediaType.anime,
    'Manga' => MediaType.manga,
    'Game' => MediaType.game,
    'Book' => MediaType.book,
    _ => null,
  };
  if (type == null) return null;
  final external = switch (type) {
    MediaType.tv || MediaType.movie => slug('tmdbId'),
    MediaType.anime => slug('malId'),
    MediaType.manga => slug('anilistId') ?? slug('malId'),
    MediaType.game => slug('igdbId'),
    MediaType.book => slug('hardcoverId'),
  };
  if (external == null) return null;
  return ListItemLink(
    type: type,
    slug: external,
    title: '${media['title'] ?? media['name'] ?? ''}',
    image:
        '${media['imageUrl'] ?? media['coverUrl'] ?? media['posterUrl'] ?? ''}',
  );
}
