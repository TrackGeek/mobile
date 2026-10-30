import 'dart:ui';

import 'package:flutter/material.dart';

import '../../styles/tg_theme.dart';
import '../../models/gallery_item.dart';
import '../../pages/media_gallery_page.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/game_screenshot.dart';
import '../../models/paginated_page.dart';
import '../../services/game_service.dart';
import '../../utils/video_links.dart';
import 'user_widgets.dart';
import '../media/smooth_image.dart';
import '../layout/tg_refresh_indicator.dart';

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
  final _revealed = <String>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
      _loaded = true;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<PaginatedPage<GameScreenshot>> _fetch(int page) =>
      widget.games.screenshots(
        userId: widget.userId,
        page: page,
        language: L10nScope.of(context).language,
      );

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      _items.addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (_) {
      // retry on next scroll
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openGallery(List<GameScreenshot> shots, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(
          title: '',
          initialIndex: index,
          items: shots.map((shot) {
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
    super.build(context);
    final theme = Theme.of(context);
    final byGame = <String, List<GameScreenshot>>{};
    for (final item in _items) {
      byGame.putIfAbsent(item.gameId, () => []).add(item);
    }
    final groups = byGame.entries.toList();
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
          _loadMore();
        }
        return false;
      },
      child: TgRefreshIndicator(
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                sliver: SliverList.separated(
                  itemCount: groups.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index >= groups.length) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final group = groups[index];
                    final shots = group.value;
                    final first = shots.first;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: widget.onOpenGame == null
                              ? null
                              : () => widget.onOpenGame!('${first.gameIgdbId}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SmoothImage(
                                  url: first.gameCoverUrl ?? '',
                                  width: 24,
                                  height: 32,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  first.gameName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 16 / 9,
                              ),
                          itemCount: shots.length,
                          itemBuilder: (context, i) {
                            final shot = shots[i];
                            final revealed =
                                !shot.isSpoiler || _revealed.contains(shot.id);
                            final video = shot.type == 'Video'
                                ? parseVideoUrl(shot.url)
                                : null;
                            final source = video != null
                                ? videoThumbnailUrl(video) ?? ''
                                : shot.url;
                            return InkWell(
                              onTap: () => revealed
                                  ? _openGallery(shots, i)
                                  : setState(() => _revealed.add(shot.id)),
                              borderRadius: BorderRadius.circular(8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: TgColors.background,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (source.isNotEmpty)
                                        ImageFiltered(
                                          enabled: !revealed,
                                          imageFilter: ImageFilter.blur(
                                            sigmaX: 16,
                                            sigmaY: 16,
                                          ),
                                          child: SmoothImage(url: source),
                                        ),
                                      if (!revealed)
                                        Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          child: Center(
                                            child: Text(
                                              context.t(
                                                'comments:spoilerReveal',
                                              ),
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
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
