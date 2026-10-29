class FollowUser {
  const FollowUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    username: '${json['username'] ?? ''}',
    avatarUrl: json['profile'] is Map<String, dynamic>
        ? (json['profile'] as Map)['avatarUrl'] as String?
        : null,
  );
}

class FollowEntry {
  const FollowEntry({required this.id, this.follower, this.following});

  final String id;
  final FollowUser? follower;
  final FollowUser? following;

  factory FollowEntry.fromJson(Map<String, dynamic> json) => FollowEntry(
    id: '${json['id']}',
    follower: json['follower'] is Map<String, dynamic>
        ? FollowUser.fromJson(json['follower'] as Map<String, dynamic>)
        : null,
    following: json['following'] is Map<String, dynamic>
        ? FollowUser.fromJson(json['following'] as Map<String, dynamic>)
        : null,
  );
}

class FollowStatus {
  const FollowStatus({required this.isFollowing, required this.followsYou});

  final bool isFollowing;
  final bool followsYou;
}
