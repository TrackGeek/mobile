import 'feed_entry.dart';

class ProfileCommentUser {
  const ProfileCommentUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    this.avatarFrame,
    this.title,
    this.level,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final String? avatarFrame;
  final String? title;
  final int? level;

  factory ProfileCommentUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final xp = json['xp'];
    return ProfileCommentUser(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      username: '${json['username'] ?? ''}',
      avatarUrl: profile is Map<String, dynamic>
          ? profile['avatarUrl'] as String?
          : null,
      avatarFrame: profile is Map<String, dynamic>
          ? profile['avatarFrame'] as String?
          : null,
      title: profile is Map<String, dynamic>
          ? profile['title'] as String?
          : null,
      level: xp is Map<String, dynamic> ? (xp['level'] as num?)?.toInt() : null,
    );
  }
}

class ProfileComment {
  const ProfileComment({
    required this.id,
    required this.content,
    required this.isSpoiler,
    required this.userId,
    required this.user,
    this.parentId,
    this.createdAt,
    this.reactions = const [],
    this.replies = const [],
  });

  final String id;
  final String content;
  final bool isSpoiler;
  final String userId;
  final ProfileCommentUser user;
  final String? parentId;
  final DateTime? createdAt;
  final List<FeedReaction> reactions;
  final List<ProfileComment> replies;

  factory ProfileComment.fromJson(Map<String, dynamic> json) => ProfileComment(
    id: '${json['id']}',
    content: '${json['content'] ?? ''}',
    isSpoiler: json['isSpoiler'] == true,
    userId: '${json['userId'] ?? ''}',
    user: ProfileCommentUser.fromJson(
      json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : const {},
    ),
    parentId: json['parentId'] as String?,
    createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    reactions: [
      for (final r in json['reactions'] as List? ?? const [])
        if (r is Map<String, dynamic>) FeedReaction.fromJson(r),
    ],
    replies: [
      for (final r in json['replies'] as List? ?? const [])
        if (r is Map<String, dynamic>) ProfileComment.fromJson(r),
    ],
  );
}
