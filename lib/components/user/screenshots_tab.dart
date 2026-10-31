import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/game_screenshot.dart';
import '../../models/gallery_item.dart';
import '../../pages/media_gallery_page.dart';
import '../../services/game_service.dart';
import '../../styles/tg_theme.dart';
import '../../utils/numbers.dart';
import '../../utils/video_links.dart';
import '../layout/tg_refresh_indicator.dart';
import '../media/smooth_image.dart';
import 'user_widgets.dart';
import '../layout/bottom_padding.dart';

class UserScreenshotsTab extends StatefulWidget {
  const UserScreenshotsTab({
    super.key,
    required this.userId,
    required this.games,
    this.onOpenGame,
  });

  final String userId;
  final GameService games;
  final void Function(String igdbId)? onOpenGame;

  @override
  State<UserScreenshotsTab> createState() => _UserScreenshotsTabState();
}

class _UserScreenshotsTabState extends State<UserScreenshotsTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <GameScreenshot>[];
  bool _loading = false;
  bool _loaded = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final language = L10nScope.read(context).language;
      final all = <GameScreenshot>[];
      var page = 1;
      var hasNext = true;
      while (hasNext && mounted) {
        final result = await widget.games.screenshots(
          userId: widget.userId,
          page: page,
          language: language,
        );
        all.addAll(result.items);
        page = result.inPage + 1;
        hasNext = result.hasNextPage;
      }
      _items
        ..clear()
        ..addAll(all);
      _loaded = true;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openGame(List<GameScreenshot> shots) {
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: GameScreenshotsPage(
            shots: shots,
            onOpenGame: widget.onOpenGame,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final byGame = <String, List<GameScreenshot>>{};
    for (final item in _items) {
      byGame.putIfAbsent(item.gameId, () => []).add(item);
    }
    final groups = byGame.values.toList();
    return TgRefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_loading && _items.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _items.isEmpty)
            SliverFillRemaining(child: UserError(onRetry: _load))
          else if (_loaded && _items.isEmpty)
            SliverFillRemaining(
              child: UserEmpty(
                icon: HugeIcons.strokeRoundedImage01,
                title: context.t('user:noScreenshots'),
                description: context.t('user:noScreenshotsDescription'),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                BottomPadding.of(context, minimum: 24),
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) => _GameCard(
                  shots: groups[index],
                  onTap: () => _openGame(groups[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.shots, required this.onTap});

  final List<GameScreenshot> shots;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = shots.first;
    final cover = first.gameCoverUrl;
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(TgRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover != null && cover.isNotEmpty)
              SmoothImage(url: cover)
            else
              Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedGameController01,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.45, 1],
                  colors: [Colors.transparent, Color(0xE6000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    first.gameName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedImage01,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.t('user:screenshotCount', {
                          'count': shots.length,
                          'formattedCount': shots.length.humanizedCount(),
                        }),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
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

class GameScreenshotsPage extends StatefulWidget {
  const GameScreenshotsPage({super.key, required this.shots, this.onOpenGame});

  final List<GameScreenshot> shots;
  final void Function(String igdbId)? onOpenGame;

  @override
  State<GameScreenshotsPage> createState() => _GameScreenshotsPageState();
}

class _GameScreenshotsPageState extends State<GameScreenshotsPage> {
  final _revealed = <String>{};

  void _openGallery(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(
          title: '',
          initialIndex: index,
          items: widget.shots.map((shot) {
            final video = shot.type == 'Video' ? parseVideoUrl(shot.url) : null;
            return GalleryItem(
              url: video == null ? shot.url : videoThumbnailUrl(video) ?? '',
              title: shot.gameName,
              description: shot.description,
              videoUrl: video?.url,
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.shots.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          first.gameName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.onOpenGame != null)
            IconButton(
              onPressed: () => widget.onOpenGame!('${first.gameIgdbId}'),
              tooltip: first.gameName,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedGameController01,
              ),
            ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 16 / 9,
        ),
        itemCount: widget.shots.length,
        itemBuilder: (context, i) {
          final shot = widget.shots[i];
          final revealed = !shot.isSpoiler || _revealed.contains(shot.id);
          final video = shot.type == 'Video' ? parseVideoUrl(shot.url) : null;
          final source = video != null
              ? videoThumbnailUrl(video) ?? ''
              : shot.url;
          return InkWell(
            onTap: () => revealed
                ? _openGallery(i)
                : setState(() => _revealed.add(shot.id)),
            borderRadius: BorderRadius.circular(TgRadii.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TgRadii.md),
              child: ColoredBox(
                color: TgColors.background,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (source.isNotEmpty)
                      ImageFiltered(
                        enabled: !revealed,
                        imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: SmoothImage(url: source),
                      ),
                    if (!revealed)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Center(
                          child: Text(
                            context.t('comments:spoilerReveal'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    if (revealed && video != null)
                      const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
