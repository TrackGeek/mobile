import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _storageKey = 'trackgeek:episode-backfill';

enum BackfillPreference { always, never }

class BackfillStore {
  BackfillStore._(this._values);

  BackfillStore.empty() : _values = {};

  final Map<String, BackfillPreference> _values;

  static Future<BackfillStore> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return BackfillStore._({});
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return BackfillStore._({});
      return BackfillStore._({
        for (final entry in decoded.entries)
          if (entry.value == 'always')
            '${entry.key}': BackfillPreference.always
          else if (entry.value == 'never')
            '${entry.key}': BackfillPreference.never,
      });
    } catch (_) {
      return BackfillStore._({});
    }
  }

  BackfillPreference? get(String key) => _values[key];

  Future<void> set(String key, BackfillPreference preference) async {
    _values[key] = preference;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          for (final entry in _values.entries) entry.key: entry.value.name,
        }),
      );
    } catch (_) {}
  }
}

typedef SeasonWatchData = ({
  int seasonNumber,
  int totalEpisodes,
  List<int> watchedEpisodes,
});

typedef SeasonEpisodeRef = ({int season, int episode});

List<int> unwatchedPreviousEpisodes({
  required int totalEpisodes,
  required List<int> watchedEpisodes,
  required int targetEpisode,
}) {
  final watched = watchedEpisodes.toSet();
  return [
    for (var episode = 1; episode <= targetEpisode - 1; episode++)
      if (!watched.contains(episode)) episode,
  ];
}

List<SeasonEpisodeRef> unwatchedPreviousSeasonEpisodes(
  List<SeasonWatchData> seasons,
  int targetSeason,
  int targetEpisode,
) {
  final previous = <SeasonEpisodeRef>[];
  for (final season in seasons) {
    final isSpecials = season.seasonNumber == 0;
    final isPreviousSeason = !isSpecials && season.seasonNumber < targetSeason;
    final isCurrentSeason = season.seasonNumber == targetSeason;
    if (!isPreviousSeason && !isCurrentSeason) continue;
    final lastEpisode = isCurrentSeason
        ? targetEpisode - 1
        : season.totalEpisodes;
    final watched = season.watchedEpisodes.toSet();
    for (var episode = 1; episode <= lastEpisode; episode++) {
      if (watched.contains(episode)) continue;
      previous.add((season: season.seasonNumber, episode: episode));
    }
  }
  return previous;
}
