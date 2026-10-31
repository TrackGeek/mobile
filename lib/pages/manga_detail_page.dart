import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../styles/tg_theme.dart';
import '../components/details/community_stats.dart';
import '../components/details/detail_overview.dart';
import '../components/details/detail_review_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/details/external_links_row.dart';
import '../components/details/genre_pills.dart';
import '../components/details/manga_tracking_sheet.dart';
import '../components/details/media_list_card.dart';
import '../components/details/people_cards.dart';
import '../components/details/refresh_data.dart';
import '../components/details/relations_view.dart';
import '../components/details/tracking.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../components/user/star_rating.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/manga_detail.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/user_list.dart';
import '../services/favorite_service.dart';
import '../services/list_service.dart';
import '../services/manga_service.dart';
import '../services/review_service.dart';
import '../utils/dates.dart';
import '../utils/genres.dart';
import '../utils/manga_links.dart';
import '../utils/release.dart';
import 'media_detail_page.dart';
import 'person_page.dart';
import '../components/layout/edgy.dart';
import '../components/layout/tg_refresh_indicator.dart';
import '../utils/haptics.dart';
import '../utils/numbers.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = TgStatus.planning;
const _readingColor = TgStatus.active;
const _completedColor = TgStatus.completed;

const _relationLabelKeys = {
  'sequel': 'sequel',
  'prequel': 'prequel',
  'side story': 'sideStory',
  'parent story': 'parent',
  'alternative version': 'alternative',
  'alternative setting': 'alternative',
  'spin-off': 'spinOff',
  'adaptation': 'adaptation',
  'summary': 'summary',
  'character': 'character',
  'full story': 'fullStory',
  'other': 'other',
};

class MangaDetailPage extends StatefulWidget {
  const MangaDetailPage({
    super.key,
    required this.anilistId,
    required this.env,
  });

  final String anilistId;
  final MediaDetailEnv env;

  @override
  State<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  late final MangaService _manga;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;

  MangaDetail? _mangaDetail;
  var _loading = true;
  ApiException? _error;

  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;

  MangaProgress? _progress;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];

  var _statusBusy = false;
  var _favoriteBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  bool get _unreleased =>
      isMediaUnreleased(MediaType.manga, status: _mangaDetail?.status);

  @override
  void initState() {
    super.initState();
    _manga = MangaService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.read(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final manga = await _manga.detail(
        int.parse(widget.anilistId),
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _mangaDetail = manga;
        _loading = false;
      });
      unawaited(_loadSecondary(manga));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = const ApiException(ApiFailure.invalidResponse);
        });
      }
    }
  }

  Future<void> _loadSecondary(MangaDetail manga) async {
    final language = L10nScope.of(context).language;
    unawaited(
      _reviews
          .mediaReviews(MediaType.manga, mediaId: manga.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.manga,
            mediaId: manga.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _manga
            .progress(userId, manga.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.manga, manga.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.manga, mediaId: manga.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.manga,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.manga, mediaId: manga.id)
            .then((v) => mounted ? setState(() => _listStatus = v) : null)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _reloadTracking() async {
    final manga = _mangaDetail;
    final userId = _userId;
    if (manga == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _manga
        .progress(userId, manga.id)
        .catchError((_) => _progress);
    final review = await _reviews
        .ownReview(MediaType.manga, mediaId: manga.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.manga, mediaId: manga.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.manga,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.manga,
        mediaId: manga.id,
        itemsPerPage: 50,
        language: language,
      );
    } catch (_) {
      containing = _containingLists;
    }
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _ownReview = review;
      _listStatus = listStatus;
      _userLists = userLists;
      _containingLists = containing;
    });
    widget.env.progress?.refresh();
  }

  Future<void> _setStatus(String status) async {
    final manga = _mangaDetail;
    if (manga == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _manga.deleteProgress(current.id);
      } else {
        await _manga.saveProgress(
          manga.id,
          status: status,
          startedAt: status == 'Reading'
              ? DateTime.now().toIso8601String()
              : null,
          completedAt: status == 'Completed'
              ? DateTime.now().toIso8601String()
              : null,
        );
      }
      await _reloadTracking();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticsHelper.light();
    final manga = _mangaDetail;
    if (manga == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(
        FavoriteTarget.manga,
        manga.id,
        _favorited ?? false,
      );
      if (mounted) {
        setState(() => _favorited = !(_favorited ?? false));
      }
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _refreshData() async {
    final manga = _mangaDetail;
    if (manga == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _manga.refresh(manga.anilistId);
      await _load();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _react(UserReview review, String emoji) async {
    if (_reactingReview != null || !_loggedIn) return;
    FeedReaction? current;
    for (final r in review.reactions) {
      if (r.userId == _userId) {
        current = r;
        break;
      }
    }
    setState(() => _reactingReview = review.id);
    try {
      await _reviews.toggleReaction(
        review,
        emoji: emoji,
        currentReaction: current,
      );
      await _loadReviews();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _reactingReview = null);
    }
  }

  Future<void> _loadReviews() async {
    final manga = _mangaDetail;
    if (manga == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.manga,
        mediaId: manga.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  Future<void> _deleteReview(UserReview review) async {
    try {
      await _reviews.deleteReview(review);
      await _loadReviews();
      _reloadTracking();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    }
  }

  void _openMoreOptions() {
    final manga = _mangaDetail;
    final userId = _userId;
    if (manga == null || userId == null) return;
    MangaTrackingSheet.open(
      context,
      manga: manga,
      mangaService: _manga,
      reviews: _reviews,
      lists: _lists,
      userId: userId,
      unreleased: _unreleased,
      progress: _progress,
      ownReview: _ownReview,
      userLists: _userLists,
      listStatus: _listStatus,
      isFavorited: _favorited ?? false,
      favoriteBusy: _favoriteBusy,
      onToggleFavorite: _toggleFavorite,
      onChanged: () {
        _reloadTracking();
        _loadReviews();
      },
    );
  }

  void _writeReview() {
    if (_progress?.status != 'Completed') {
      _setStatus('Completed');
    }
    _openMoreOptions();
  }

  void _openCastPerson(int anilistId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonPage(
          request: MangaCastRequest('$anilistId'),
          people: widget.env.people,
          details: widget.env.details,
          favorites: widget.env.favorites,
          session: widget.env.session,
          api: widget.env.api,
          onOpenUser: widget.env.onOpenUser,
          onOpenGenre: widget.env.onOpenGenre,
        ),
      ),
    );
  }

  void _openMedia(MediaType type, String id) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: type,
          id: id,
          details: widget.env.details,
          env: widget.env,
        ),
      ),
    );
  }

  void _openRelation(MangaRelationNode node) {
    final segments = node.link
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.length != 2) return;
    final type = switch (segments[0]) {
      'manga' => MediaType.manga,
      'anime' => MediaType.anime,
      _ => null,
    };
    if (type == null) return;
    _openMedia(type, segments[1]);
  }

  void _toast(String key) {
    key == 'api:INTERNAL_SERVER_ERROR'
        ? HapticsHelper.error()
        : HapticsHelper.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(key))));
  }

  String? get _publishedRange {
    final published = _mangaDetail?.published;
    if (published == null) return null;
    return formatDateRange(
          published.from,
          published.to,
          L10nScope.of(context).language,
          presentLabel: context.t('library:present'),
        ) ??
        published.string;
  }

  @override
  Widget build(BuildContext context) {
    final manga = _mangaDetail;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          manga?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (manga != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/manga/${manga.anilistId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || manga == null
          ? DetailErrorState(onRetry: _load)
          : TgRefreshIndicator(
              onRefresh: _load,
              child: ContentFrame(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 960 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.6;
                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wide) ...[
                          _buildHeader(manga),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(manga),
                        const SizedBox(height: 32),
                        _buildReviews(manga),
                      ],
                    );
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildSidebar(manga)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          _buildHeader(manga),
                          const SizedBox(height: 24),
                          _buildSidebar(manga),
                          const SizedBox(height: 24),
                          content,
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildSidebar(MangaDetail manga) {
    final theme = Theme.of(context);
    final release = _publishedRange;
    final links = mangaExternalLinks(manga);
    final altTitles = manga.alternativeTitles;
    return DetailOverview(
      cover: CoverArt(url: manga.imageUrl),
      children: [
        if (_loggedIn) ...[
          const SizedBox(height: 14),
          QuickStatusButtons(
            buttons: [
              StatusButtonConfig(
                label: context.t('feed:lists.planning'),
                icon: HugeIcons.strokeRoundedBookmark01,
                color: _planningColor,
                isActive: _progress?.status == 'Planning',
                disabled: _statusBusy,
                onTap: () => _setStatus('Planning'),
              ),
              if (!_unreleased)
                StatusButtonConfig(
                  label: context.t('feed:lists.reading'),
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  color: theme.colorScheme.primary,
                  isActive: _progress?.status == 'Reading',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Reading'),
                ),
              if (!_unreleased)
                StatusButtonConfig(
                  label: context.t('feed:lists.read'),
                  icon: HugeIcons.strokeRoundedCheckmarkSquare02,
                  color: _completedColor,
                  isActive: _progress?.status == 'Completed',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Completed'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMoreOptions,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMenu02,
                size: 16,
              ),
              label: Text(context.t('library:moreOptions')),
            ),
          ),
        ],
        if (manga.status != null || release != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (manga.status != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('common:status'),
                    value: manga.status!,
                  ),
                ),
              if (manga.status != null && release != null)
                const SizedBox(width: 10),
              if (release != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('common:releaseDate'),
                    value: release,
                  ),
                ),
            ],
          ),
        ],
        if (altTitles.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLanguageSkill,
                        size: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.t('library:alternativeTitles'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                for (var i = 0; i < altTitles.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      altTitles[i].title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_loggedIn) ...[
          const SizedBox(height: 10),
          RefreshDataCard(
            lastRefreshedAt: manga.lastRefreshedAt,
            sourceUrl: manga.url,
            pending: _refreshing,
            onRefresh: _refreshData,
          ),
        ],
        if (links.isNotEmpty) ...[
          const SizedBox(height: 14),
          ExternalLinksRow(links: links),
        ],
      ],
    );
  }

  Widget _buildHeader(MangaDetail manga) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          manga.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRating(value: manga.tgReviewScore),
                const SizedBox(width: 6),
                Text(
                  manga.tgReviewScore.toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${context.t('common:reviewCount', {'count': reviews?.total ?? 0, 'formattedCount': (reviews?.total ?? 0).humanizedCount()})})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs(MangaDetail manga) {
    final cast = manga.cast;
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      if (manga.characters.isNotEmpty)
        ('characters', context.t('library:characters')),
      if (cast.isNotEmpty) ('staff', context.t('library:staff')),
      (
        'lists',
        '${context.t('common:lists')} (${(_containingLists?.total ?? 0).humanizedCount()})',
      ),
    ];
    if (_tab >= tabs.length) _tab = 0;
    final selected = tabs[_tab].$1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Edgy(
          axis: .horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _tab == i,
                      label: Text(tabs[i].$2),
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        switch (selected) {
          'info' => _infoTab(manga),
          'characters' => _charactersTab(manga),
          'staff' => _staffTab(cast),
          _ => _listsTab(manga),
        },
      ],
    );
  }

  Widget _infoTab(MangaDetail manga) {
    final theme = Theme.of(context);
    final stats = manga.progressStats;
    final relations = _relationNodes(manga);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (manga.synopsis != null && manga.synopsis!.isNotEmpty)
          Text(
            manga.synopsis!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (manga.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: manga.genres,
              labelOf: (g) => genreLabel(context, g),
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.manga, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:mangaCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(manga))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
        if (relations.isNotEmpty) ...[
          const SizedBox(height: 8),
          DetailSection(
            title: context.t('library:relations'),
            child: RelationsView(
              rootTitle: manga.title,
              rootImageUrl: manga.imageUrl,
              nodes: relations,
              onOpen: (id) {
                final node = manga.relations!.nodes.firstWhere(
                  (n) => int.tryParse(n.id) == id,
                );
                _openRelation(node);
              },
            ),
          ),
        ],
        if (stats != null) ...[
          const SizedBox(height: 8),
          DetailSection(
            title: context.t('library:communityStatistics'),
            child: CommunityStats(
              stats: [
                CommunityStatItem(
                  label: context.t('feed:lists.planning'),
                  icon: HugeIcons.strokeRoundedBookmark01,
                  color: _planningColor,
                  percentage:
                      '${stats.planning.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.planning.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.reading'),
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  color: _readingColor,
                  percentage: '${stats.reading.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.reading.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.read'),
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: _completedColor,
                  percentage:
                      '${stats.completed.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.completed.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.dropped'),
                  icon: HugeIcons.strokeRoundedCancelCircle,
                  color: theme.colorScheme.error,
                  percentage: '${stats.dropped.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.dropped.count,
                  }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<RelationNode> _relationNodes(MangaDetail manga) {
    final relations = manga.relations;
    if (relations == null ||
        relations.edges.isEmpty ||
        relations.nodes.length < 2) {
      return const [];
    }
    return [
      for (final node in relations.nodes)
        if (node.relationShip != 'Now' && int.tryParse(node.id) != null)
          RelationNode(
            id: int.parse(node.id),
            title: node.name,
            label: _relationLabel(node.relationShip),
            imageUrl: node.image.isEmpty ? null : node.image,
          ),
    ];
  }

  String _relationLabel(String relationShip) {
    final key = _relationLabelKeys[relationShip.toLowerCase()];
    if (key == null) return relationShip;
    return context.t('library:relationships.$key');
  }

  List<Widget> _characteristicCards(MangaDetail manga) {
    final themes = [
      for (final theme in manga.themes) genreLabel(context, theme),
    ];
    return [
      if (manga.type != null)
        InfoCard(
          title: context.t('library:type'),
          icon: HugeIcons.strokeRoundedFile01,
          description: Text(manga.type!),
        ),
      if (manga.numberOfChapters != null)
        InfoCard(
          title: context.t('library:chapters'),
          icon: HugeIcons.strokeRoundedBookOpen01,
          description: Text(manga.numberOfChapters!.humanizedCount()),
        ),
      if (manga.numberOfVolumes != null)
        InfoCard(
          title: context.t('library:volumes'),
          icon: HugeIcons.strokeRoundedSwatchBook,
          description: Text(manga.numberOfVolumes!.humanizedCount()),
        ),
      if (themes.isNotEmpty)
        InfoCard(
          title: context.t('library:themes'),
          icon: HugeIcons.strokeRoundedTags,
          description: ListWithMore(
            entries: [for (final theme in themes) (label: theme, onTap: null)],
          ),
        ),
      if (manga.authors.isNotEmpty)
        InfoCard(
          title: context.t('library:authors'),
          icon: HugeIcons.strokeRoundedPencil,
          description: ListWithMore(
            entries: [
              for (final person in manga.authors)
                (
                  label: person.label,
                  onTap: () => _openCastPerson(person.anilistId),
                ),
            ],
          ),
        ),
      if (manga.serializations.isNotEmpty)
        InfoCard(
          title: context.t('library:staff'),
          icon: HugeIcons.strokeRoundedNotebook,
          description: ListWithMore(
            entries: [
              for (final person in manga.serializations)
                (
                  label: person.label,
                  onTap: () => _openCastPerson(person.anilistId),
                ),
            ],
          ),
        ),
    ];
  }

  Widget _charactersTab(MangaDetail manga) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: AdaptiveGridDelegate(
        context: context,
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.50,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: manga.characters.length,
      itemBuilder: (context, index) {
        final character = manga.characters[index];
        return PersonTile(name: character.name, imageUrl: character.imageUrl);
      },
    );
  }

  Widget _staffTab(List<MangaCast> cast) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: AdaptiveGridDelegate(
        context: context,
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.50,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cast.length,
      itemBuilder: (context, index) {
        final person = cast[index];
        return PersonTile(
          name: person.name,
          subtitle: person.role,
          imageUrl: person.imageUrl,
          onTap: () => _openCastPerson(person.anilistId),
        );
      },
    );
  }

  Widget _listsTab(MangaDetail manga) {
    final lists = _containingLists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loggedIn)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _openMoreOptions,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAddToList,
                size: 15,
              ),
              label: Text(context.t('feed:customLists')),
            ),
          ),
        if (lists == null)
          const Center(child: CircularProgressIndicator())
        else if (lists.items.isEmpty)
          EmptyBlock(
            icon: HugeIcons.strokeRoundedListView,
            title: context.t('library:noLists'),
            description: context.t('library:noListsDescription'),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: AdaptiveGridDelegate(
              context: context,
              maxCrossAxisExtent: 260,
              childAspectRatio: 1.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: lists.items.length,
            itemBuilder: (context, index) => MediaListCard(
              list: lists.items[index],
              lists: _lists,
              onOpenMedia: _openMedia,
              onOpenUser: widget.env.onOpenUser,
            ),
          ),
      ],
    );
  }

  Widget _buildReviews(MangaDetail manga) {
    final reviews = _reviewsPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${context.t('common:reviews')} (${(reviews?.total ?? 0).humanizedCount()})',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (_loggedIn && !_unreleased)
              OutlinedButton.icon(
                onPressed: _writeReview,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  size: 14,
                ),
                label: Text(context.t('feed:review')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews == null)
          const Center(child: CircularProgressIndicator())
        else if (reviews.items.isEmpty)
          EmptyBlock(
            icon: HugeIcons.strokeRoundedStar,
            title: context.t('library:noReviews'),
            description: context.t('library:noReviewsDescription'),
          )
        else
          for (final review in reviews.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DetailReviewCard(
                review: review,
                currentUserId: _userId ?? '',
                isOwner: review.user?.id == _userId,
                onUserTap: widget.env.onOpenUser == null || review.user == null
                    ? null
                    : () => widget.env.onOpenUser!(review.user!.username),
                onEdit: review.user?.id == _userId ? _openMoreOptions : null,
                onDelete: review.user?.id == _userId
                    ? () => _deleteReview(review)
                    : null,
                onReact: (emoji, current) => _react(review, emoji),
                reacting: _reactingReview == review.id,
              ),
            ),
      ],
    );
  }
}
