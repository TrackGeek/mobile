import 'episode_backfill.dart';

final _runtimePattern = RegExp(
  r'^(?:(\d+)\s*hr\.?\s*)?(?:(\d+)\s*min\.?\s*)?(?:(\d+)\s*sec\.?)?(?:\s*per\s*ep\.?)?$',
  caseSensitive: false,
);

double? episodeRuntimeMinutes(String? duration) {
  if (duration == null) return null;
  final match = _runtimePattern.firstMatch(duration.trim());
  if (match == null) return null;
  final minutes =
      (num.tryParse(match.group(1) ?? '') ?? 0) * 60 +
      (num.tryParse(match.group(2) ?? '') ?? 0) +
      (num.tryParse(match.group(3) ?? '') ?? 0) / 60;
  return minutes > 0 ? minutes.toDouble() : null;
}

double? episodeRuntimeMinutesFromValues(List<num> runtimes) {
  final valid = [
    for (final r in runtimes)
      if (r.isFinite && r > 0) r,
  ];
  if (valid.isEmpty) return null;
  return valid.reduce((a, b) => a + b) / valid.length;
}

double? remainingWatchHours({
  required int totalEpisodes,
  required List<int> watchedEpisodes,
  required double? runtimeMinutes,
}) {
  final runtime = runtimeMinutes;
  if (runtime == null || !runtime.isFinite || runtime <= 0) return null;
  if (totalEpisodes <= 0) return null;
  final watched = watchedEpisodes
      .where((e) => e >= 1 && e <= totalEpisodes)
      .toSet();
  final remaining = totalEpisodes - watched.length;
  return (remaining * runtime / 6).ceil() / 10;
}

double? remainingSeasonWatchHours(
  List<SeasonWatchData> seasons,
  double? runtimeMinutes,
) {
  final runtime = runtimeMinutes;
  if (runtime == null || !runtime.isFinite || runtime <= 0) return null;
  if (seasons.isEmpty) return null;
  if (seasons.any((s) => s.totalEpisodes <= 0)) return null;
  var remaining = 0;
  for (final season in seasons) {
    final watched = season.watchedEpisodes
        .where((e) => e >= 1 && e <= season.totalEpisodes)
        .toSet();
    remaining += season.totalEpisodes - watched.length;
  }
  return (remaining * runtime / 6).ceil() / 10;
}
