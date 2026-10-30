import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/tg_theme.dart';
import '../components/details/community_stats.dart';
import '../components/details/detail_overview.dart';
import '../components/details/detail_review_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/details/game_media_carousel.dart';
import '../components/details/game_tracking_sheet.dart';
import '../components/details/genre_pills.dart';
import '../components/details/media_list_card.dart';
import '../components/details/refresh_data.dart';
import '../components/details/relations_view.dart';
import '../components/details/tracking.dart';
import '../components/details/website_icon.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../components/user/star_rating.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/gallery_item.dart';
import '../models/game_detail.dart';
import '../models/game_screenshot.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/user_list.dart';
import '../pages/media_gallery_page.dart';
import '../services/favorite_service.dart';
import '../services/game_service.dart';
import '../services/list_service.dart';
import '../services/review_service.dart';
import '../utils/dates.dart';
import '../utils/genres.dart';
import '../utils/release.dart';
import '../utils/video_links.dart';
import 'company_page.dart';
import 'game_franchise_page.dart';
import 'media_detail_page.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = TgStatus.planning;
const _completedColor = TgStatus.completed;

class GameDetailPage extends StatefulWidget {
  const GameDetailPage({super.key, required this.igdbId, required this.env});

  final String igdbId;
  final MediaDetailEnv env;

  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  late final GameService _games;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;
  final _scroll = ScrollController();

  GameDetail? _game;
  var _loading = true;
  ApiException? _error;

  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;

  GameProgress? _progress;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];

  final _shots = <GameScreenshot>[];
  var _shotsPage = 0;
  var _shotsTotal = 0;
  var _shotsHasNext = false;
  var _shotsLoading = false;
  final _revealed = <String>{};

  var _statusBusy = false;
  var _favoriteBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  bool get _unreleased =>
      isMediaUnreleased(MediaType.game, status: _game?.gameStatus);

  @override
  void initState() {
    super.initState();
    _games = GameService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _scroll.addListener(_maybeLoadMoreShots);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final language = L10nScope.read(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final game = await _games.detail(
        int.parse(widget.igdbId),
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _game = game;
        _loading = false;
      });
      unawaited(_loadSecondary(game));
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

  Future<void> _loadSecondary(GameDetail game) async {
    final language = L10nScope.of(context).language;
    unawaited(
      _reviews
          .mediaReviews(MediaType.game, mediaId: game.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.game,
            mediaId: game.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _games
          .screenshots(gameId: game.id, itemsPerPage: 20, language: language)
          .then((v) {
            if (!mounted) return;
            setState(() {
              _shots
                ..clear()
                ..addAll(v.items);
              _shotsPage = v.inPage;
              _shotsTotal = v.total ?? v.items.length;
              _shotsHasNext = v.hasNextPage;
            });
          })
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _games
            .progress(userId, game.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.game, game.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.game, mediaId: game.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.game,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.game, mediaId: game.id)
            .then((v) => mounted ? setState(() => _listStatus = v) : null)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _reloadTracking() async {
    final game = _game;
    final userId = _userId;
    if (game == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _games
        .progress(userId, game.id)
        .catchError((_) => _progress);
    final review = await _reviews
        .ownReview(MediaType.game, mediaId: game.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.game, mediaId: game.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.game,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.game,
        mediaId: game.id,
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

  void _maybeLoadMoreShots() {
    final tabs = _tabKeys();
    if (tabs.isEmpty || tabs[_tab] != 'screenshots') return;
    if (_shotsLoading || !_shotsHasNext || _game == null) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 300) {
      return;
    }
    _loadMoreShots();
  }

  Future<void> _loadMoreShots() async {
    final game = _game;
    if (game == null) return;
    setState(() => _shotsLoading = true);
    try {
      final page = await _games.screenshots(
        gameId: game.id,
        page: _shotsPage + 1,
        itemsPerPage: 20,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _shots.addAll(page.items);
        _shotsPage = page.inPage;
        _shotsHasNext = page.hasNextPage;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _shotsLoading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    final game = _game;
    if (game == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _games.deleteProgress(current.id);
      } else {
        await _games.saveProgress(
          game.id,
          status: status,
          startedAt: status == 'Playing'
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
    final game = _game;
    if (game == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(
        FavoriteTarget.game,
        game.id,
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
    final game = _game;
    if (game == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _games.refresh(game.igdbId);
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
    final game = _game;
    if (game == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.game,
        mediaId: game.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  void _openMoreOptions() {
    final game = _game;
    final userId = _userId;
    if (game == null || userId == null) return;
    GameTrackingSheet.open(
      context,
      game: game,
      gameService: _games,
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

  void _openCompany(int companyId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyPage(
          type: MediaType.game,
          id: '$companyId',
          env: widget.env,
        ),
      ),
    );
  }

  void _openFranchise(GameFranchiseRef franchise) {
    final slug = franchise.slug;
    if (slug == null || slug.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameFranchisePage(slug: slug, env: widget.env),
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toast(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(key))));
  }

  List<String> _tabKeys() => [
    'info',
    'lists',
    if (_shotsTotal > 0) 'screenshots',
  ];

  @override
  Widget build(BuildContext context) {
    final game = _game;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          game?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (game != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/game/${game.igdbId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || game == null
          ? DetailErrorState(onRetry: _load)
          : RefreshIndicator(
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
                          _buildHeader(game),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(game),
                        const SizedBox(height: 32),
                        _buildReviews(game),
                      ],
                    );
                    return ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildSidebar(game)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          _buildHeader(game),
                          const SizedBox(height: 24),
                          _buildSidebar(game),
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

  Widget _buildSidebar(GameDetail game) {
    final theme = Theme.of(context);
    final release = formatLongDate(
      game.firstReleaseDate,
      L10nScope.of(context).language,
    );
    final websites = [
      for (final w in game.websites)
        if (w.url.isNotEmpty) w,
    ];
    return DetailOverview(
      cover: CoverArt(url: game.displayCoverUrl),
      children: [
        if (_loggedIn) ...[
          const SizedBox(height: 14),
          QuickStatusButtons(
            buttons: [
              StatusButtonConfig(
                label: context.t('feed:lists.wanttoplay'),
                icon: HugeIcons.strokeRoundedBookmark01,
                color: _planningColor,
                isActive: _progress?.status == 'Planning',
                disabled: _statusBusy,
                onTap: () => _setStatus('Planning'),
              ),
              if (!_unreleased)
                StatusButtonConfig(
                  label: context.t('feed:lists.playing'),
                  icon: HugeIcons.strokeRoundedGameController01,
                  color: theme.colorScheme.primary,
                  isActive: _progress?.status == 'Playing',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Playing'),
                ),
              if (!_unreleased)
                StatusButtonConfig(
                  label: context.t('feed:lists.played'),
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
        if (game.gameStatus != null || release != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (game.gameStatus != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('common:status'),
                    value: game.gameStatus!,
                  ),
                ),
              if (game.gameStatus != null && release != null)
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
        if (_loggedIn) ...[
          const SizedBox(height: 10),
          RefreshDataCard(
            lastRefreshedAt: game.lastRefreshedAt,
            sourceUrl: 'https://www.igdb.com/games/${game.slug}',
            pending: _refreshing,
            onRefresh: _refreshData,
          ),
        ],
        if (websites.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final website in websites)
                WebsiteIcon(
                  website: website,
                  onTap: () => _openUrl(website.url),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(GameDetail game) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    final franchise = game.franchises.isEmpty ? null : game.franchises.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          game.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (franchise != null && franchise.name.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openFranchise(franchise),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedPackage,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    franchise.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (reviews != null && (reviews.total ?? 0) >= 1)
          Row(
            children: [
              StarRating(value: game.tgReviewScore),
              const SizedBox(width: 6),
              Text(
                game.tgReviewScore.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${context.t('common:reviewCount', {'count': reviews.total ?? 0})})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTabs(GameDetail game) {
    final keys = _tabKeys();
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      (
        'lists',
        '${context.t('common:lists')} (${_containingLists?.total ?? 0})',
      ),
      if (_shotsTotal > 0)
        ('screenshots', '${context.t('common:screenshots')} ($_shotsTotal)'),
    ];
    if (_tab >= tabs.length) _tab = 0;
    final selected = keys[_tab];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
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
        const SizedBox(height: 16),
        switch (selected) {
          'info' => _infoTab(game),
          'lists' => _listsTab(game),
          'screenshots' => _screenshotsTab(game),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }

  List<RelationNode> _relationNodes(GameDetail game) {
    String label(String key) => context.t('library:relationships.$key');
    final nodes = <RelationNode>[];
    void add(List<RelatedGame> games, String key) {
      for (final g in games) {
        if (g.id <= 0) continue;
        nodes.add(
          RelationNode(
            id: g.id,
            title: g.name,
            label: label(key),
            imageUrl: g.coverUrl,
          ),
        );
      }
    }

    final parent = game.parentGame;
    if (parent != null && parent.id > 0) {
      nodes.add(
        RelationNode(
          id: parent.id,
          title: parent.name,
          label: label('parent'),
          imageUrl: parent.coverUrl,
        ),
      );
    }
    add(game.prequels, 'prequel');
    add(game.expandedGames, 'expandedGame');
    add(game.sequels, 'sequel');
    add(game.dlcs, 'dlc');
    add(game.expansions, 'expansion');
    add(game.ports, 'port');
    add(game.remakes, 'remake');
    add(game.remasters, 'remaster');
    add(game.bundles, 'bundle');
    return nodes;
  }

  Widget _infoTab(GameDetail game) {
    final theme = Theme.of(context);
    final stats = game.progressStats;
    final relations = _relationNodes(game);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((game.summary ?? game.storyline)?.isNotEmpty == true)
          Text(
            (game.summary ?? game.storyline)!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (game.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: game.genres,
              labelOf: (g) => genreLabel(context, g),
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.game, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:gameCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(game))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
        if (relations.isNotEmpty) ...[
          const SizedBox(height: 8),
          DetailSection(
            title: context.t('library:relations'),
            child: RelationsView(
              rootTitle: game.name,
              rootImageUrl: game.displayCoverUrl,
              nodes: relations,
              onOpen: (id) => _openMedia(MediaType.game, '$id'),
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
                  label: context.t('feed:lists.wanttoplay'),
                  icon: HugeIcons.strokeRoundedBookmark01,
                  color: _planningColor,
                  percentage:
                      '${stats.planToPlay.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.planToPlay.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.playing'),
                  icon: HugeIcons.strokeRoundedGameController01,
                  color: theme.colorScheme.primary,
                  percentage: '${stats.playing.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.playing.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.played'),
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
        if (game.videos.isNotEmpty || game.screenshots.isNotEmpty) ...[
          const SizedBox(height: 16),
          GameMediaCarousel(game: game, onOpenUrl: _openUrl),
        ],
      ],
    );
  }

  List<Widget> _characteristicCards(GameDetail game) {
    Widget companyLinks(List<GameCompany> companies) => Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < companies.length; i++) ...[
          if (i > 0) const Text(', '),
          companies[i].companyId != null
              ? InkWell(
                  onTap: () => _openCompany(companies[i].companyId!),
                  child: Text(
                    companies[i].name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : Text(companies[i].name),
        ],
      ],
    );

    Widget names(List<String> values) => Text(values.join(', '));

    return [
      if (game.developers.isNotEmpty)
        InfoCard(
          title: context.t('library:developers'),
          icon: HugeIcons.strokeRoundedCode,
          description: companyLinks(game.developers),
        ),
      if (game.publishers.isNotEmpty)
        InfoCard(
          title: context.t('library:publishers'),
          icon: HugeIcons.strokeRoundedBuilding03,
          description: companyLinks(game.publishers),
        ),
      if (game.platformNames.isNotEmpty)
        InfoCard(
          title: context.t('library:platforms'),
          icon: HugeIcons.strokeRoundedComputer,
          description: names(game.platformNames),
        ),
      if (game.themes.isNotEmpty)
        InfoCard(
          title: context.t('library:themes'),
          icon: HugeIcons.strokeRoundedMaskTheater01,
          description: names(game.themes),
        ),
      if (game.gameModes.isNotEmpty)
        InfoCard(
          title: context.t('library:gameModes'),
          icon: HugeIcons.strokeRoundedNeuralNetwork,
          description: names(game.gameModes),
        ),
      if (game.playerPerspectives.isNotEmpty)
        InfoCard(
          title: context.t('library:playerPerspectives'),
          icon: HugeIcons.strokeRoundedCctvCamera,
          description: names(game.playerPerspectives),
        ),
      if (game.gameEngines.isNotEmpty)
        InfoCard(
          title: context.t('library:gameEngine'),
          icon: HugeIcons.strokeRoundedBug01,
          description: names(game.gameEngines),
        ),
    ];
  }

  Widget _listsTab(GameDetail game) {
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

  Widget _screenshotsTab(GameDetail game) {
    final theme = Theme.of(context);
    if (_shots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 16 / 9,
          ),
          itemCount: _shots.length,
          itemBuilder: (context, index) {
            final shot = _shots[index];
            final revealed = !shot.isSpoiler || _revealed.contains(shot.id);
            final video = shot.type == 'Video' ? parseVideoUrl(shot.url) : null;
            final source = video != null
                ? videoThumbnailUrl(video) ?? ''
                : shot.url;
            return InkWell(
              onTap: () => revealed
                  ? _openGallery(_shots, index)
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
                          imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Image.network(
                            source,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      if (!revealed)
                        Container(
                          color: Colors.black.withValues(alpha: 0.4),
                          child: Center(
                            child: Text(
                              context.t('comments:spoilerReveal'),
                              textAlign: TextAlign.center,
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
        if (_shotsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_shotsHasNext)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              context.t('common:loading'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  void _openGallery(List<GameScreenshot> shots, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(
          title: _game?.name ?? '',
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

  Widget _buildReviews(GameDetail game) {
    final reviews = _reviewsPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${context.t('common:reviews')} (${reviews?.total ?? 0})',
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

  Future<void> _deleteReview(UserReview review) async {
    try {
      await _reviews.deleteReview(review);
      await _loadReviews();
      _reloadTracking();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    }
  }
}
