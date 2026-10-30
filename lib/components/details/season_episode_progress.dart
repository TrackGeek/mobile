import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../utils/episode_backfill.dart';

class SeasonEpisodeProgress extends StatefulWidget {
  const SeasonEpisodeProgress({
    super.key,
    required this.seasons,
    this.defaultSeason,
    this.seasonCustomNames = const {},
    required this.onToggleEpisode,
    this.onToggleSeason,
    this.onToggleAll,
    this.busy = false,
  });

  final List<SeasonWatchData> seasons;
  final int? defaultSeason;
  final Map<int, String> seasonCustomNames;
  final void Function(int seasonNumber, int episode) onToggleEpisode;
  final void Function(int seasonNumber, bool watched)? onToggleSeason;
  final void Function(bool watched)? onToggleAll;
  final bool busy;

  @override
  State<SeasonEpisodeProgress> createState() => _SeasonEpisodeProgressState();
}

class _SeasonEpisodeProgressState extends State<SeasonEpisodeProgress> {
  int? _activeSeason;

  int? get _initialSeason {
    final fallback = widget.defaultSeason;
    if (fallback != null &&
        widget.seasons.any((s) => s.seasonNumber == fallback)) {
      return fallback;
    }
    return widget.seasons.isEmpty ? null : widget.seasons.first.seasonNumber;
  }

  @override
  void initState() {
    super.initState();
    _activeSeason = _initialSeason;
  }

  @override
  void didUpdateWidget(SeasonEpisodeProgress old) {
    super.didUpdateWidget(old);
    if (_activeSeason == null ||
        !widget.seasons.any((s) => s.seasonNumber == _activeSeason)) {
      _activeSeason = _initialSeason;
    }
  }

  String _seasonLabel(int seasonNumber) =>
      widget.seasonCustomNames[seasonNumber] ??
      '${context.t('library:season')} $seasonNumber';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.seasons.isEmpty) return const SizedBox.shrink();
    final active = _activeSeason;
    SeasonWatchData? current;
    for (final s in widget.seasons) {
      if (s.seasonNumber == active) {
        current = s;
        break;
      }
    }
    if (current == null) return const SizedBox.shrink();
    final season = current;
    final seasonWatched = season.watchedEpisodes.length >= season.totalEpisodes;
    final allWatched = widget.seasons.every(
      (s) => s.watchedEpisodes.length >= s.totalEpisodes,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in widget.seasons)
                    _SeasonTab(
                      label: _seasonLabel(s.seasonNumber),
                      watched: s.watchedEpisodes.length,
                      total: s.totalEpisodes,
                      active: s.seasonNumber == active,
                      onTap: widget.busy
                          ? null
                          : () =>
                                setState(() => _activeSeason = s.seasonNumber),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('library:selectWatchedEpisodes'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (widget.busy)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (widget.onToggleSeason != null)
                      InkWell(
                        onTap: widget.busy
                            ? null
                            : () => widget.onToggleSeason!(
                                season.seasonNumber,
                                !seasonWatched,
                              ),
                        child: Text(
                          seasonWatched
                              ? context.t('library:unmarkSeason')
                              : context.t('library:markSeason', {
                                  'season': season.seasonNumber,
                                }),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.onToggleSeason != null &&
                        widget.onToggleAll != null)
                      Container(
                        width: 1,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: theme.colorScheme.outlineVariant,
                      ),
                    if (widget.onToggleAll != null)
                      InkWell(
                        onTap: widget.busy
                            ? null
                            : () => widget.onToggleAll!(!allWatched),
                        child: Text(
                          allWatched
                              ? context.t('library:unmarkAll')
                              : context.t('library:markAll'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (
                      var episode = 1;
                      episode <= season.totalEpisodes;
                      episode++
                    )
                      _EpisodeCell(
                        episode: episode,
                        watched: season.watchedEpisodes.contains(episode),
                        onTap: widget.busy
                            ? null
                            : () => widget.onToggleEpisode(
                                season.seasonNumber,
                                episode,
                              ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonTab extends StatelessWidget {
  const _SeasonTab({
    required this.label,
    required this.watched,
    required this.total,
    required this.active,
    this.onTap,
  });

  final String label;
  final int watched;
  final int total;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? (watched / total * 100).round() : 0;
    return Material(
      color: active ? theme.colorScheme.surface : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: active
                ? Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: active
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$watched/$total${progress > 0 ? ' ($progress%)' : ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell({
    required this.episode,
    required this.watched,
    this.onTap,
  });

  final int episode;
  final bool watched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: watched
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          border: Border.all(
            color: watched
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          '$episode',
          style: theme.textTheme.labelMedium?.copyWith(
            color: watched
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
