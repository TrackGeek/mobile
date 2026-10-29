import 'package:flutter/material.dart';

import '../layout/adaptive_grid_delegate.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/tv_detail.dart';
import 'detail_widgets.dart';

class SeasonEpisodesSection extends StatefulWidget {
  const SeasonEpisodesSection({
    super.key,
    required this.seasons,
    required this.loadEpisodes,
    this.initialSeason,
  });

  final List<TvSeason> seasons;
  final Future<List<TvSeasonEpisode>> Function(int seasonNumber) loadEpisodes;
  final int? initialSeason;

  @override
  State<SeasonEpisodesSection> createState() => _SeasonEpisodesSectionState();
}

class _SeasonEpisodesSectionState extends State<SeasonEpisodesSection> {
  final _cache = <int, List<TvSeasonEpisode>>{};
  final _failed = <int>{};
  final _pending = <int>{};

  Future<void> _ensureLoaded(int seasonNumber) async {
    if (_cache.containsKey(seasonNumber) || _pending.contains(seasonNumber)) {
      return;
    }
    setState(() => _pending.add(seasonNumber));
    try {
      final episodes = await widget.loadEpisodes(seasonNumber);
      if (!mounted) return;
      setState(() {
        _cache[seasonNumber] = episodes;
        _failed.remove(seasonNumber);
      });
    } catch (_) {
      if (mounted) setState(() => _failed.add(seasonNumber));
    } finally {
      if (mounted) setState(() => _pending.remove(seasonNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.seasons.isEmpty) {
      return EmptyBlock(
        icon: HugeIcons.strokeRoundedTv01,
        title: context.t('library:noEpisodes'),
      );
    }
    final defaultOpen =
        widget.initialSeason != null &&
            widget.seasons.any((s) => s.seasonNumber == widget.initialSeason)
        ? widget.initialSeason
        : (widget.seasons.any((s) => s.seasonNumber == 1)
              ? 1
              : widget.seasons.first.seasonNumber);
    return Column(
      children: [
        for (final season in widget.seasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SeasonTile(
              season: season,
              initiallyExpanded: season.seasonNumber == defaultOpen,
              episodes: _cache[season.seasonNumber],
              loading: _pending.contains(season.seasonNumber),
              failed: _failed.contains(season.seasonNumber),
              onExpand: () => _ensureLoaded(season.seasonNumber),
              onRetry: () => _ensureLoaded(season.seasonNumber),
            ),
          ),
      ],
    );
  }
}

class _SeasonTile extends StatelessWidget {
  const _SeasonTile({
    required this.season,
    required this.initiallyExpanded,
    required this.episodes,
    required this.loading,
    required this.failed,
    required this.onExpand,
    required this.onRetry,
  });

  final TvSeason season;
  final bool initiallyExpanded;
  final List<TvSeasonEpisode>? episodes;
  final bool loading;
  final bool failed;
  final VoidCallback onExpand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('season-${season.seasonNumber}'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: (open) {
          if (open) onExpand();
        },
        title: Text(
          season.name.isNotEmpty
              ? season.name
              : '${context.t('library:season')} ${season.seasonNumber}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: season.numberOfEpisodes > 0
            ? Text(
                '${season.numberOfEpisodes} ${context.t('library:episode_other')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
        children: [
          if (loading)
            const _EpisodeSkeleton()
          else if (failed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton(
                  onPressed: onRetry,
                  child: Text(context.t('common:tryAgain')),
                ),
              ),
            )
          else if (episodes == null)
            const _EpisodeSkeleton()
          else if (episodes!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.t('library:noEpisodes'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: AdaptiveGridDelegate(
                context: context,
                maxCrossAxisExtent: 300,
                childAspectRatio: 16 / 9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: episodes!.length,
              itemBuilder: (context, index) =>
                  TvEpisodeCard(episode: episodes![index]),
            ),
        ],
      ),
    );
  }
}

class _EpisodeSkeleton extends StatelessWidget {
  const _EpisodeSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 16 / 9,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (var i = 0; i < 6; i++)
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    );
  }
}

class TvEpisodeCard extends StatelessWidget {
  const TvEpisodeCard({super.key, required this.episode});

  final TvSeasonEpisode episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (episode.stillUrl?.isNotEmpty == true)
              Image.network(
                episode.stillUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: theme.colorScheme.surfaceContainerHighest),
              )
            else
              Container(color: theme.colorScheme.surfaceContainerHighest),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    episode.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${context.t('library:episode')} ${episode.episodeNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
