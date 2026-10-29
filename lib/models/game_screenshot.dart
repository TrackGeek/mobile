class GameScreenshot {
  const GameScreenshot({
    required this.id,
    required this.url,
    required this.type,
    required this.isSpoiler,
    this.description,
    required this.gameId,
    required this.gameIgdbId,
    required this.gameName,
    this.gameCoverUrl,
  });

  final String id;
  final String url;
  final String type;
  final bool isSpoiler;
  final String? description;
  final String gameId;
  final int gameIgdbId;
  final String gameName;
  final String? gameCoverUrl;

  factory GameScreenshot.fromJson(Map<String, dynamic> json) {
    final game = json['game'];
    return GameScreenshot(
      id: '${json['id']}',
      url: '${json['url'] ?? ''}',
      type: '${json['type'] ?? 'Image'}',
      isSpoiler: json['isSpoiler'] == true,
      description: json['description'] as String?,
      gameId: game is Map<String, dynamic> ? '${game['id']}' : '',
      gameIgdbId: game is Map<String, dynamic>
          ? (game['igdbId'] as num?)?.toInt() ?? 0
          : 0,
      gameName: game is Map<String, dynamic> ? '${game['name'] ?? ''}' : '',
      gameCoverUrl: game is Map<String, dynamic>
          ? game['coverUrl'] as String?
          : null,
    );
  }
}
