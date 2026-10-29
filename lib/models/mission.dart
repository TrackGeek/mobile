class UserMission {
  const UserMission({
    required this.id,
    required this.key,
    required this.tier,
    required this.hidden,
    required this.progress,
    required this.target,
    required this.percentage,
    this.completedAt,
    this.metric,
    this.contentType,
    this.xpReward = 0,
    this.coinReward = 0,
    this.cosmeticKey,
    this.medalName,
    this.medalImageUrl,
  });

  final String id;
  final String key;
  final String tier;
  final bool hidden;
  final int progress;
  final int target;
  final double percentage;
  final String? completedAt;
  final String? metric;
  final String? contentType;
  final int xpReward;
  final int coinReward;
  final String? cosmeticKey;
  final String? medalName;
  final String? medalImageUrl;

  bool get isCompleted => completedAt != null;
  bool get masked => hidden && !isCompleted;

  factory UserMission.fromJson(Map<String, dynamic> json) => UserMission(
    id: '${json['id']}',
    key: '${json['key'] ?? ''}',
    tier: '${json['tier'] ?? 'Bronze'}',
    hidden: json['hidden'] == true,
    progress: (json['progress'] as num?)?.toInt() ?? 0,
    target: (json['target'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    completedAt: json['completedAt'] as String?,
    metric: json['metric'] as String?,
    contentType: json['contentType'] as String?,
    xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
    coinReward: (json['coinReward'] as num?)?.toInt() ?? 0,
    cosmeticKey: json['cosmeticKey'] as String?,
    medalName: json['medal'] is Map<String, dynamic>
        ? '${(json['medal'] as Map)['name'] ?? ''}'
        : null,
    medalImageUrl: json['medal'] is Map<String, dynamic>
        ? '${(json['medal'] as Map)['imageUrl'] ?? ''}'
        : null,
  );
}

class UserMissionsSummary {
  const UserMissionsSummary({
    required this.total,
    required this.completed,
    required this.items,
  });

  final int total;
  final int completed;
  final List<UserMission> items;

  factory UserMissionsSummary.fromJson(Map<String, dynamic> json) =>
      UserMissionsSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        items: [
          for (final item in json['items'] as List? ?? const [])
            if (item is Map<String, dynamic>) UserMission.fromJson(item),
        ],
      );
}
