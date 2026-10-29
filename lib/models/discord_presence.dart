class DiscordPresence {
  const DiscordPresence({
    this.linked = false,
    this.inGuild = false,
    this.status,
    this.customStatus,
    this.spotify,
    this.activities = const [],
  });

  final bool linked;
  final bool inGuild;
  final String? status;
  final String? customStatus;
  final DiscordSpotify? spotify;
  final List<DiscordActivity> activities;

  factory DiscordPresence.fromJson(Map<String, dynamic> json) =>
      DiscordPresence(
        linked: json['linked'] == true,
        inGuild: json['inGuild'] == true,
        status: json['status'] as String?,
        customStatus: json['customStatus'] as String?,
        spotify: json['spotify'] is Map<String, dynamic>
            ? DiscordSpotify.fromJson(json['spotify'] as Map<String, dynamic>)
            : null,
        activities: [
          for (final a in json['activities'] as List? ?? const [])
            if (a is Map<String, dynamic>) DiscordActivity.fromJson(a),
        ],
      );
}

class DiscordSpotify {
  const DiscordSpotify({
    required this.name,
    this.artists,
    this.album,
    this.albumArtUrl,
    this.url,
    this.startedAt,
    this.endsAt,
  });

  final String name;
  final String? artists;
  final String? album;
  final String? albumArtUrl;
  final String? url;
  final DateTime? startedAt;
  final DateTime? endsAt;

  factory DiscordSpotify.fromJson(Map<String, dynamic> json) => DiscordSpotify(
    name: '${json['name'] ?? ''}',
    artists: json['artists'] as String?,
    album: json['album'] as String?,
    albumArtUrl: json['albumArtUrl'] as String?,
    url: json['url'] as String?,
    startedAt: DateTime.tryParse('${json['startedAt'] ?? ''}'),
    endsAt: DateTime.tryParse('${json['endsAt'] ?? ''}'),
  );
}

class DiscordActivity {
  const DiscordActivity({
    required this.name,
    this.type = 0,
    this.details,
    this.state,
    this.largeImageUrl,
    this.smallImageUrl,
    this.largeText,
    this.smallText,
    this.startedAt,
  });

  final String name;
  final int type;
  final String? details;
  final String? state;
  final String? largeImageUrl;
  final String? smallImageUrl;
  final String? largeText;
  final String? smallText;
  final DateTime? startedAt;

  factory DiscordActivity.fromJson(Map<String, dynamic> json) =>
      DiscordActivity(
        name: '${json['name'] ?? ''}',
        type: (json['type'] as num?)?.toInt() ?? 0,
        details: json['details'] as String?,
        state: json['state'] as String?,
        largeImageUrl: json['largeImageUrl'] as String?,
        smallImageUrl: json['smallImageUrl'] as String?,
        largeText: json['largeText'] as String?,
        smallText: json['smallText'] as String?,
        startedAt: DateTime.tryParse('${json['startedAt'] ?? ''}'),
      );
}
