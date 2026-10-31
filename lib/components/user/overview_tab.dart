import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/favorite.dart';
import '../../models/media_type.dart';
import '../../models/user_profile.dart';
import '../../services/comment_service.dart';
import '../../services/favorite_service.dart';
import '../../services/game_service.dart';
import '../../services/user_service.dart';
import '../../utils/content_types.dart';
import '../../utils/profile_cosmetics.dart';
import '../feed/feed_markdown.dart';
import 'comments_card.dart';
import 'links_card.dart';
import 'media_card.dart';
import 'presence_cards.dart';
import 'setup_card.dart';
import 'user_widgets.dart';
import '../media/smooth_image.dart';
import '../layout/edgy.dart';
import '../../utils/numbers.dart';

class UserOverviewTab extends StatefulWidget {
  const UserOverviewTab({
    super.key,
    required this.user,
    required this.session,
    required this.users,
    required this.favorites,
    required this.comments,
    required this.games,
    this.onSeeFavorites,
    this.onSeeProgress,
    this.onOpenMedia,
    this.onOpenUser,
    this.onChanged,
  });

  final UserProfile user;
  final SessionController session;
  final UserService users;
  final FavoriteService favorites;
  final CommentService comments;
  final GameService games;
  final VoidCallback? onSeeFavorites;
  final void Function(MediaType type)? onSeeProgress;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final void Function(String username)? onOpenUser;
  final VoidCallback? onChanged;

  @override
  State<UserOverviewTab> createState() => _UserOverviewTabState();
}

class _UserOverviewTabState extends State<UserOverviewTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = widget.user;
    final viewer = widget.session.user;
    final isOwner = viewer?.id == user.id;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      children: [
        _StatisticsCard(
          user: user,
          visible: visibleMediaTypes(viewer),
          onSeeProgress: widget.onSeeProgress,
        ),
        const SizedBox(height: 16),
        if (user.profile.about.trim().isNotEmpty) ...[
          UserCard(
            title: context.t('user:bio'),
            child: MarkdownBody(
              data: user.profile.about,
              styleSheet: feedMarkdownStyleSheet(Theme.of(context)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _ActivityCard(
          userId: user.id,
          users: widget.users,
          color: user.profile.color,
        ),
        const SizedBox(height: 16),
        PresenceCards(userId: user.id, users: widget.users),
        _FavoritesPreview(
          userId: user.id,
          session: widget.session,
          favorites: widget.favorites,
          onSeeMore: widget.onSeeFavorites,
          onOpenItem: (item) {
            if (item.target == FavoriteTarget.person) return;
            final type = switch (item.target) {
              FavoriteTarget.anime => MediaType.anime,
              FavoriteTarget.manga => MediaType.manga,
              FavoriteTarget.tv => MediaType.tv,
              FavoriteTarget.movie => MediaType.movie,
              FavoriteTarget.game => MediaType.game,
              FavoriteTarget.book => MediaType.book,
              _ => null,
            };
            if (type != null) widget.onOpenMedia?.call(type, item.slug);
          },
        ),
        const SizedBox(height: 16),
        _XpCard(xp: user.xp, coins: user.coinBalance),
        if (user.userMedals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _MedalsCard(medals: user.userMedals),
        ],
        const SizedBox(height: 16),
        LinksCard(
          user: user,
          isOwner: isOwner,
          users: widget.users,
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 16),
        SetupCard(
          user: user,
          isOwner: isOwner,
          users: widget.users,
          games: widget.games,
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 16),
        CommentsCard(
          target: (type: 'Profile', id: user.profile.id),
          comments: widget.comments,
          sessionUserId: viewer?.id,
          canModerate: isOwner,
          onOpenUser: widget.onOpenUser,
        ),
      ],
    );
  }
}

const _statConfig = [
  (
    'anime',
    MediaType.anime,
    'common:types.anime_other',
    HugeIcons.strokeRoundedMountain,
  ),
  (
    'manga',
    MediaType.manga,
    'common:types.manga_other',
    HugeIcons.strokeRoundedBookOpen01,
  ),
  (
    'tvShow',
    MediaType.tv,
    'common:types.tv_other',
    HugeIcons.strokeRoundedTv01,
  ),
  (
    'movie',
    MediaType.movie,
    'common:types.movie_other',
    HugeIcons.strokeRoundedClapperboard,
  ),
  (
    'game',
    MediaType.game,
    'common:types.game_other',
    HugeIcons.strokeRoundedGameController01,
  ),
  (
    'book',
    MediaType.book,
    'common:types.book_other',
    HugeIcons.strokeRoundedBook01,
  ),
];

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.user,
    required this.visible,
    this.onSeeProgress,
  });

  final UserProfile user;
  final Set<MediaType> visible;
  final void Function(MediaType type)? onSeeProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UserCard(
      title: context.t('user:statistics'),
      child: GridView.extent(
        maxCrossAxisExtent: 180,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent:
            110 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 3,
        children: [
          for (final (key, type, labelKey, icon) in _statConfig)
            if (visible.contains(type))
              InkWell(
                onTap: () => onSeeProgress?.call(type),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HugeIcon(
                        icon: icon,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t(labelKey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${user.progressStats[key]?.total ?? 0}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.userId, required this.users, this.color});

  final String userId;
  final UserService users;
  final String? color;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  ActivityCalendar? _calendar;
  bool _loading = false;
  String _selected = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      _calendar = await widget.users.activityCalendar(
        widget.userId,
        language: L10nScope.of(context).language,
      );
      _selected = '';
    } catch (_) {
      _calendar = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final calendar = _calendar;
    final accent =
        parseHexColor(isGradientColor(widget.color) ? null : widget.color) ??
        theme.colorScheme.primary;
    return UserCard(
      title: context.t('user:activity'),
      child: _loading && calendar == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected.isEmpty
                      ? context.t('user:activityLastYear', {
                          'value': (calendar?.total ?? 0).humanizedCount(),
                        })
                      : _selected,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _Heatmap(
                  counts: calendar?.items ?? const {},
                  accent: accent,
                  onTapDay: (date, count) => setState(
                    () => _selected = context.t('user:activityTooltip', {
                      'value': count == 0
                          ? context.t('user:activityNoCount')
                          : count.humanizedCount(),
                      'date': DateFormat.yMd(locale).format(date),
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.counts,
    required this.accent,
    required this.onTapDay,
  });

  final Map<String, int> counts;
  final Color accent;
  final void Function(DateTime date, int count) onTapDay;

  static const _weeks = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final end = DateTime(today.year, today.month, today.day);
    final start = end.subtract(
      Duration(days: (_weeks * 7) - 1 + end.weekday % 7),
    );
    final max = counts.values.fold(0, (m, c) => c > m ? c : m);
    return SizedBox(
      height: 7 * 11 + 12,
      child: Edgy(
        axis: .horizontal,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _weeks + 1,
          separatorBuilder: (_, _) => const SizedBox(width: 3),
          itemBuilder: (context, week) {
            final weekStart = start.add(Duration(days: week * 7));
            return Column(
              children: [
                for (var day = 0; day < 7; day++) ...[
                  Builder(
                    builder: (context) {
                      final date = weekStart.add(Duration(days: day));
                      if (date.isAfter(end)) {
                        return const SizedBox(width: 10, height: 10);
                      }
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final count = counts[key] ?? 0;
                      final intensity = max == 0 ? 0.0 : (count / max);
                      return GestureDetector(
                        onTap: () => onTapDay(date, count),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? theme.colorScheme.surfaceContainerHighest
                                : accent.withValues(
                                    alpha: 0.25 + intensity * 0.75,
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                  if (day < 6) const SizedBox(height: 3),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FavoritesPreview extends StatefulWidget {
  const _FavoritesPreview({
    required this.userId,
    required this.session,
    required this.favorites,
    this.onSeeMore,
    this.onOpenItem,
  });

  final String userId;
  final SessionController session;
  final FavoriteService favorites;
  final VoidCallback? onSeeMore;
  final void Function(FavoriteItem item)? onOpenItem;

  @override
  State<_FavoritesPreview> createState() => _FavoritesPreviewState();
}

class _FavoritesPreviewState extends State<_FavoritesPreview> {
  List<FavoriteItem> _items = const [];
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page = await widget.favorites.favoritesByUser(
        widget.userId,
        itemsPerPage: 6,
        language: L10nScope.of(context).language,
      );
      _items = [for (final favorite in page.items) ?favoriteToItem(favorite)];
      _loaded = true;
    } catch (_) {
      _items = const [];
      _loaded = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _items.isEmpty) return const SizedBox.shrink();
    return UserCard(
      title: context.t('user:favorites'),
      trailing: TextButton(
        onPressed: widget.onSeeMore,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(context.t('common:showMore')),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              height: 190,
              child: Edgy(
                axis: .horizontal,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return SizedBox(
                      width: 110,
                      child: MediaCard(
                        title: item.title,
                        image: item.image,
                        onTap: () => widget.onOpenItem?.call(item),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

const _xpTypeConfig = {
  'Anime': ('common:types.anime_other', HugeIcons.strokeRoundedMountain),
  'Manga': ('common:types.manga_other', HugeIcons.strokeRoundedBookOpen01),
  'TVShow': ('common:types.tv_other', HugeIcons.strokeRoundedTv01),
  'Movie': ('common:types.movie_other', HugeIcons.strokeRoundedClapperboard),
  'Game': ('common:types.game_other', HugeIcons.strokeRoundedGameController01),
  'Book': ('common:types.book_other', HugeIcons.strokeRoundedBook01),
};

class _XpCard extends StatelessWidget {
  const _XpCard({required this.xp, required this.coins});

  final XpSummary xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capped = xp.nextLevelXp <= 0 || xp.percentage >= 100;
    return UserCard(
      title: context.t('xp:progression'),
      subtitle: 'XP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.t('xp:levelShort', {'level': xp.level}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.t('xp:totalXp', {'count': xp.totalXp}),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (xp.percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            capped
                ? context.t('xp:maxProgress')
                : context.t('xp:toNextLevel', {
                    'current': xp.currentLevelXp,
                    'next': xp.nextLevelXp,
                    'level': xp.level + 1,
                  }),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: HugeIcons.strokeRoundedFire,
                  title: xp.currentStreak > 0
                      ? context.t('common:dayCount', {
                          'count': xp.currentStreak,
                        })
                      : context.t('xp:noStreak'),
                  subtitle: context.t('xp:longestStreak', {
                    'count': xp.longestStreak,
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: HugeIcons.strokeRoundedCoins01,
                  title: context.t('common:coinCount', {'count': coins}),
                  subtitle: context.t('xp:coins'),
                ),
              ),
            ],
          ),
          if (xp.contentTypes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              context.t('xp:byContentType'),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in xp.contentTypes)
                  if (_xpTypeConfig[entry.contentType] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: _xpTypeConfig[entry.contentType]!.$2,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t('xp:levelShort', {'level': entry.level}),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            context.t(_xpTypeConfig[entry.contentType]!.$1),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(
            icon: icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalsCard extends StatelessWidget {
  const _MedalsCard({required this.medals});

  final List<UserMedal> medals;

  @override
  Widget build(BuildContext context) => UserCard(
    title: context.t('user:medals'),
    child: SizedBox(
      height: 64,
      child: Edgy(
        axis: .horizontal,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: medals.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final medal = medals[index];
            final level = RegExp(r'^level-(\d+)$').firstMatch(medal.name)?[1];
            final label = level != null
                ? context.t('medals:level.name', {'level': level})
                : context.t('medals:${medal.name}.name');
            return Tooltip(
              message: label,
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: SmoothImage(
                  url: medal.imageUrl,
                  fit: BoxFit.contain,
                  error: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAward01,
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
