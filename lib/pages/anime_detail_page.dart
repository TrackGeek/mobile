import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/tg_theme.dart';
import '../components/details/community_stats.dart';
import '../components/details/detail_overview.dart';
import '../components/details/detail_review_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/details/external_links_row.dart';
import '../components/details/genre_pills.dart';
import '../components/details/media_list_card.dart';
import '../components/details/people_cards.dart';
import '../components/details/refresh_data.dart';
import '../components/details/relations_view.dart';
import '../components/details/tracking.dart';
import '../components/details/tracking_sheet.dart';
import '../components/details/trailer_card.dart';
import '../components/details/watch_links_row.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../components/user/star_rating.dart';
import '../l10n/l10n_context.dart';
import '../models/anime_detail.dart';
import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/user_list.dart';
import '../models/watch_link.dart';
import '../services/anime_service.dart';
import '../services/favorite_service.dart';
import '../services/list_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../utils/anime_links.dart';
import '../utils/episode_backfill.dart';
import '../utils/release.dart';
import '../utils/video_links.dart';
import '../utils/watch_links.dart';
import '../utils/watch_time.dart';
import 'company_page.dart';
import 'media_detail_page.dart';
import 'person_page.dart';
import '../components/layout/edgy.dart';
import '../components/layout/tg_refresh_indicator.dart';
import '../utils/haptics.dart';
import '../utils/numbers.dart';
import '../components/layout/bottom_padding.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = TgStatus.planning;
const _watchingColor = TgStatus.active;
const _completedColor = TgStatus.completed;
const _chartBlue = TgStatus.info;

class AnimeDetailPage extends StatefulWidget {
  const AnimeDetailPage({super.key, required this.slug, required this.env});

  final String slug;
  final MediaDetailEnv env;

  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  late final AnimeService _animeService;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;
  late final SettingsService _settings;

  AnimeDetail? _anime;
  var _loading = true;
  ApiException? _error;

  final _episodes = <AnimeEpisode>[];
  var _episodePage = 0;
  var _episodePages = 0;
  var _episodesLoading = false;
  var _episodesFailed = false;

  List<AnimeRelation>? _relations;
  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;
  List<WatchLink> _watchLinks = const [];

  AnimeProgress? _progress;
  List<AnimeEpisodeWatch>? _episodeWatch;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];
  BackfillStore _backfill = BackfillStore.empty();

  var _statusBusy = false;
  var _episodeBusy = false;
  var _favoriteBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;
  final Map<int, GlobalKey> _chipKeys = {};

  String get _backfillKey => 'anime:${_anime?.id}';

  List<int> get _watchedEpisodes => [
    for (final w in _episodeWatch ?? const <AnimeEpisodeWatch>[])
      if (w.status == 'Completed') w.episode,
  ];

  bool get _unreleased =>
      isMediaUnreleased(MediaType.anime, status: _anime?.status);

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _settings = SettingsService(widget.env.api);
    BackfillStore.load().then((store) => _backfill = store);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.read(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final anime = await _animeService.detail(widget.slug, language: language);
      if (!mounted) return;
      setState(() {
        _anime = anime;
        _loading = false;
      });
      unawaited(_loadSecondary(anime));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _loadSecondary(AnimeDetail anime) async {
    final language = L10nScope.of(context).language;
    unawaited(_loadEpisodes());
    unawaited(
      _animeService
          .relations('${anime.malId}', language: language)
          .then((v) => mounted ? setState(() => _relations = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _reviews
          .mediaReviews(MediaType.anime, mediaId: anime.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.anime,
            mediaId: anime.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _animeService
            .progress(userId, anime.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _animeService
            .episodeWatch(userId, anime.id)
            .then((v) => mounted ? setState(() => _episodeWatch = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.anime, anime.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.anime, mediaId: anime.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.anime,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.anime, mediaId: anime.id)
            .then((v) => mounted ? setState(() => _listStatus = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _settings
            .watchLinks()
            .then(
              (v) => mounted
                  ? setState(
                      () => _watchLinks = [
                        for (final l in v)
                          if (l.enabled &&
                              l.contentTypes.contains(
                                watchLinkContentType[MediaType.anime],
                              ))
                            l,
                      ],
                    )
                  : null,
            )
            .catchError((_) {}),
      );
    }
  }

  Future<void> _loadEpisodes() async {
    if (_episodesLoading || _anime == null) return;
    if (_episodePages > 0 && _episodePage >= _episodePages) return;
    _episodesLoading = true;
    _episodesFailed = false;
    try {
      final page = await _animeService.episodes(
        '${_anime!.malId}',
        page: _episodePage + 1,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _episodes.addAll(page.items);
        _episodePage = page.inPage;
        _episodePages = page.pages ?? page.inPage;
        _episodesLoading = false;
      });
    } catch (_) {
      _episodesLoading = false;
      if (mounted) setState(() => _episodesFailed = true);
    }
  }

  Future<void> _reloadTracking() async {
    final anime = _anime;
    final userId = _userId;
    if (anime == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _animeService
        .progress(userId, anime.id)
        .catchError((_) => _progress);
    final watch = await _animeService
        .episodeWatch(userId, anime.id)
        .catchError((_) => _episodeWatch ?? <AnimeEpisodeWatch>[]);
    final review = await _reviews
        .ownReview(MediaType.anime, mediaId: anime.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.anime, mediaId: anime.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.anime,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.anime,
        mediaId: anime.id,
        itemsPerPage: 50,
        language: language,
      );
    } catch (_) {
      containing = _containingLists;
    }
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _episodeWatch = watch;
      _ownReview = review;
      _listStatus = listStatus;
      _userLists = userLists;
      _containingLists = containing;
    });
    widget.env.progress?.refresh();
  }

  Future<void> _setStatus(String status) async {
    final anime = _anime;
    if (anime == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _animeService.deleteProgress(current.id);
      } else {
        await _animeService.saveProgress(
          anime.id,
          status: status,
          startedAt: status == 'Watching'
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

  Future<void> _startWatchingIfNeeded() async {
    final current = _progress;
    final anime = _anime;
    if (anime == null) return;
    if (current != null && current.status != 'Planning') return;
    try {
      await _animeService.saveProgress(
        anime.id,
        status: 'Watching',
        startedAt: DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  Future<void> _toggleEpisode(int episode) async {
    final anime = _anime;
    if (anime == null || _episodeBusy) return;
    final watched = _watchedEpisodes;
    if (watched.contains(episode)) {
      await _runEpisodeOp(() async {
        await _animeService.unwatchEpisode(anime.id, episode);
      });
      return;
    }
    final total = anime.numberOfEpisodes ?? 0;
    final previous = unwatchedPreviousEpisodes(
      totalEpisodes: total,
      watchedEpisodes: watched,
      targetEpisode: episode,
    );
    final preference = _backfill.get(_backfillKey);
    if (previous.isEmpty || preference == BackfillPreference.never) {
      await _runEpisodeOp(() async {
        await _animeService.watchEpisodes(anime.id, [episode]);
        await _startWatchingIfNeeded();
      });
      return;
    }
    if (preference == BackfillPreference.always) {
      await _runEpisodeOp(() async {
        await _animeService.watchEpisodes(anime.id, [...previous, episode]);
        await _startWatchingIfNeeded();
      });
      return;
    }
    if (!mounted) return;
    await BackfillDialog.show(
      context,
      episodeCount: previous.length,
      onConfirm: (remember) async {
        if (remember) {
          await _backfill.set(_backfillKey, BackfillPreference.always);
        }
        await _runEpisodeOp(() async {
          await _animeService.watchEpisodes(anime.id, [...previous, episode]);
          await _startWatchingIfNeeded();
        });
      },
      onDecline: (remember) async {
        if (remember) {
          await _backfill.set(_backfillKey, BackfillPreference.never);
        }
        await _runEpisodeOp(() async {
          await _animeService.watchEpisodes(anime.id, [episode]);
          await _startWatchingIfNeeded();
        });
      },
    );
  }

  Future<void> _runEpisodeOp(Future<void> Function() op) async {
    if (_episodeBusy) return;
    setState(() => _episodeBusy = true);
    try {
      await op();
      await _reloadTracking();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _episodeBusy = false);
    }
  }

  Future<void> _toggleFavorite() async {
    HapticsHelper.light();
    final anime = _anime;
    if (anime == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(
        FavoriteTarget.anime,
        anime.id,
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
    final anime = _anime;
    if (anime == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _animeService.refresh('${anime.malId}');
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
    final language = L10nScope.of(context).language;
    try {
      await _reviews.toggleReaction(
        review,
        emoji: emoji,
        currentReaction: current,
      );
      final page = await _reviews.mediaReviews(
        MediaType.anime,
        mediaId: _anime!.id,
        language: language,
      );
      if (mounted) setState(() => _reviewsPage = page);
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _reactingReview = null);
    }
  }

  void _openMoreOptions() {
    final anime = _anime;
    final userId = _userId;
    if (anime == null || userId == null) return;
    TrackingSheet.open(
      context,
      anime: anime,
      animeService: _animeService,
      reviews: _reviews,
      lists: _lists,
      userId: userId,
      unreleased: _unreleased,
      progress: _progress,
      ownReview: _ownReview,
      episodeWatch: _episodeWatch ?? const [],
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

  Future<void> _loadReviews() async {
    final anime = _anime;
    if (anime == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.anime,
        mediaId: anime.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  void _writeReview() {
    final status = _progress?.status;
    if (status != 'Completed') {
      _setStatus('Completed');
    }
    _openMoreOptions();
  }

  void _openCompany(int malId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CompanyPage(type: MediaType.anime, id: '$malId', env: widget.env),
      ),
    );
  }

  void _openPerson(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonPage(
          request: PersonSlugRequest(slug),
          people: widget.env.people,
          details: widget.env.details,
          favorites: widget.env.favorites,
          session: widget.env.session,
          api: widget.env.api,
          onOpenUser: widget.env.onOpenUser,
        ),
      ),
    );
  }

  void _openMedia(MediaType type, String slug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: type,
          id: slug,
          details: widget.env.details,
          env: widget.env,
        ),
      ),
    );
  }

  void _toast(String key) {
    key == 'api:INTERNAL_SERVER_ERROR'
        ? HapticsHelper.error()
        : HapticsHelper.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(key))));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final anime = _anime;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          anime?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (anime != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/anime/${anime.malId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || anime == null
          ? DetailErrorState(onRetry: _load)
          : TgRefreshIndicator(
              onRefresh: _load,
              child: ContentFrame(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 960 &&
                        MediaQuery.textScalerOf(context).scale(1) < 1.6;
                    final inset = wide ? 0.0 : 16.0;
                    final content = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (wide) ...[
                          _buildHeader(anime),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(anime, inset),
                        const SizedBox(height: 32),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: _buildReviews(anime),
                        ),
                      ],
                    );
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 16 : 0,
                        16,
                        wide ? 16 : 0,
                        BottomPadding.of(context, minimum: 40),
                      ),
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildSidebar(anime)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildHeader(anime),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSidebar(anime),
                          ),
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

  Widget _buildSidebar(AnimeDetail anime) {
    final theme = Theme.of(context);
    return DetailOverview(
      cover: CoverArt(url: malImage(anime.imageUrl)),
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
              StatusButtonConfig(
                label: context.t('feed:lists.watching'),
                icon: HugeIcons.strokeRoundedVideo01,
                color: _watchingColor,
                isActive: _progress?.status == 'Watching',
                disabled: _statusBusy,
                onTap: () => _setStatus('Watching'),
              ),
              StatusButtonConfig(
                label: context.t('feed:lists.completed'),
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
        const SizedBox(height: 14),
        Row(
          children: [
            if (anime.status != null)
              Expanded(
                child: MetaStatCard(
                  label: context.t('common:status'),
                  value: anime.status!,
                ),
              ),
            if (anime.status != null &&
                anime.season != null &&
                anime.year != null)
              const SizedBox(width: 10),
            if (anime.season != null && anime.year != null)
              Expanded(
                child: MetaStatCard(
                  label: context.t('common:releaseDate'),
                  value: '${anime.season} ${anime.year}',
                ),
              ),
          ],
        ),
        if (anime.alternativeTitles.isNotEmpty) ...[
          const SizedBox(height: 10),
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                for (final entry in anime.alternativeTitles)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Text(
                      entry.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (_loggedIn) ...[
          const SizedBox(height: 10),
          RefreshDataCard(
            lastRefreshedAt: anime.lastRefreshedAt,
            sourceUrl: 'https://myanimelist.net/anime/${anime.malId}',
            pending: _refreshing,
            onRefresh: _refreshData,
          ),
        ],
        if (animeExternalLinks(anime).isNotEmpty) ...[
          const SizedBox(height: 10),
          ExternalLinksRow(links: animeExternalLinks(anime)),
        ],
      ],
    );
  }

  Widget _buildHeader(AnimeDetail anime) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    final runtime = episodeRuntimeMinutes(anime.duration);
    final remaining = remainingWatchHours(
      totalEpisodes: anime.numberOfEpisodes ?? 0,
      watchedEpisodes: _watchedEpisodes,
      runtimeMinutes: runtime,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          anime.title,
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
            if (reviews != null && (reviews.total ?? 0) >= 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarRating(value: anime.tgReviewScore),
                  const SizedBox(width: 6),
                  Text(
                    anime.tgReviewScore.toStringAsFixed(1),
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
            if (_loggedIn &&
                _progress?.status == 'Watching' &&
                _episodeWatch != null)
              TimeLeft(hours: remaining),
          ],
        ),
      ],
    );
  }

  void _scrollToTab(int i) {
    final ctx = _chipKeys[i]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTabs(AnimeDetail anime, double inset) {
    final hasEpisodes = _episodes.isNotEmpty;
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      if (hasEpisodes) ('episodes', context.t('library:episode_other')),
      ('cast', context.t('common:types.cast')),
      ('characters', context.t('library:characters')),
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
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Padding(
                    key: _chipKeys.putIfAbsent(i, GlobalKey.new),
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _tab == i,
                      label: Text(tabs[i].$2),
                      onSelected: (_) {
                        setState(() => _tab = i);
                        _scrollToTab(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: inset),
          child: switch (selected) {
            'info' => _infoTab(anime),
            'episodes' => _episodesTab(),
            'cast' => _castTab(anime),
            'characters' => _charactersTab(anime),
            _ => _listsTab(anime),
          },
        ),
      ],
    );
  }

  Widget _infoTab(AnimeDetail anime) {
    final theme = Theme.of(context);
    final stats = anime.progressStats;
    final trailer = anime.trailerEmbedUrl == null
        ? null
        : parseVideoUrl(anime.trailerEmbedUrl!.replaceAll('&autoplay=1', ''));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anime.synopsis != null && anime.synopsis!.isNotEmpty)
          Text(
            anime.synopsis!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (anime.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: anime.genres,
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.anime, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:animeCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(anime))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
        if ((_relations ?? const []).isNotEmpty) ...[
          const SizedBox(height: 8),
          DetailSection(
            title: context.t('library:relations'),
            child: RelationsView(
              rootTitle: anime.title,
              rootImageUrl: anime.imageUrl,
              nodes: buildAnimeRelationNodes(
                _relations!,
                (key) => context.t('library:relationships.$key'),
              ),
              onOpen: (malId) => _openMedia(MediaType.anime, '$malId'),
            ),
          ),
        ],
        if (_watchLinks.isNotEmpty || widget.env.onOpenSettings != null) ...[
          const SizedBox(height: 16),
          CustomWatchLinks(
            links: _watchLinks,
            linkContext: WatchLinkContext(
              mediaType: MediaType.anime,
              malId: anime.malId,
              title: anime.englishTitle ?? anime.title,
              titleRomaji: anime.title,
              episode: nextWatchEpisode(_watchedEpisodes),
            ),
            onManage: widget.env.onOpenSettings,
          ),
        ],
        if (_loggedIn && !_unreleased && (anime.numberOfEpisodes ?? 0) > 0) ...[
          const SizedBox(height: 16),
          EpisodeProgressGrid(
            totalEpisodes: anime.numberOfEpisodes!,
            watchedEpisodes: _watchedEpisodes,
            busy: _episodeBusy,
            onToggle: _toggleEpisode,
          ),
        ],
        if (stats != null) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:communityStatistics'),
            child: CommunityStats(
              stats: [
                CommunityStatItem(
                  label: context.t('feed:lists.planning'),
                  icon: HugeIcons.strokeRoundedBookmark01,
                  color: _planningColor,
                  percentage:
                      '${stats.planToWatch.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.planToWatch.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.watching'),
                  icon: HugeIcons.strokeRoundedVideo01,
                  color: _chartBlue,
                  percentage:
                      '${stats.watching.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.watching.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.completed'),
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: _watchingColor,
                  percentage:
                      '${stats.completed.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.completed.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.dropped'),
                  icon: HugeIcons.strokeRoundedCancelCircle,
                  color: Theme.of(context).colorScheme.error,
                  percentage: '${stats.dropped.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.dropped.count,
                  }),
                ),
              ],
            ),
          ),
        ],
        if (trailer != null) ...[
          const SizedBox(height: 16),
          TrailerCard(video: trailer, onTap: () => _openUrl(trailer.url)),
        ],
      ],
    );
  }

  List<Widget> _characteristicCards(AnimeDetail anime) {
    return [
      if (anime.type != null)
        InfoCard(
          title: context.t('library:type'),
          icon: HugeIcons.strokeRoundedFile01,
          description: Text(anime.type!),
        ),
      if (anime.source != null)
        InfoCard(
          title: context.t('library:source'),
          icon: HugeIcons.strokeRoundedSourceCode,
          description: Text(anime.source!),
        ),
      if (anime.numberOfEpisodes != null)
        InfoCard(
          title: context.t('library:totalEpisodes'),
          icon: HugeIcons.strokeRoundedVideo01,
          description: Text(anime.numberOfEpisodes!.humanizedCount()),
        ),
      if (anime.broadcast != null && anime.broadcast!.isNotEmpty)
        InfoCard(
          title: context.t('library:broadcast'),
          icon: HugeIcons.strokeRoundedAntenna,
          description: Text(anime.broadcast!),
        ),
      if (anime.rating != null)
        InfoCard(
          title: context.t('library:rating'),
          icon: HugeIcons.strokeRoundedShieldUser,
          description: Text(anime.rating!),
        ),
      if (anime.duration != null)
        InfoCard(
          title: context.t('library:runtime'),
          icon: HugeIcons.strokeRoundedClock01,
          description: Text(anime.duration!),
        ),
      if (anime.studios.isNotEmpty)
        InfoCard(
          title: context.t('library:studios'),
          icon: HugeIcons.strokeRoundedBuilding03,
          description: _companyLinks(anime.studios),
        ),
      if (anime.producers.isNotEmpty)
        InfoCard(
          title: context.t('library:producers'),
          icon: HugeIcons.strokeRoundedBuilding06,
          description: _companyLinks(anime.producers),
        ),
    ];
  }

  Widget _companyLinks(List<AnimeCompanyRef> companies) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final company in companies)
          InkWell(
            onTap: () => _openCompany(company.malId),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                company.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _episodesTab() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: AdaptiveGridDelegate(
            context: context,
            maxCrossAxisExtent: 200,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _episodes.length,
          itemBuilder: (context, index) {
            final episode = _episodes[index];
            return EpisodeCard(
              number: episode.episodeNumber,
              title: episode.title,
              imageUrl: episode.imageUrl,
            );
          },
        ),
        if (_episodePage < _episodePages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: _episodesLoading
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _loadEpisodes,
                      child: Text(context.t('common:showMore')),
                    ),
            ),
          ),
        if (_episodesFailed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: _loadEpisodes,
              child: Text(context.t('api:INTERNAL_SERVER_ERROR')),
            ),
          ),
      ],
    );
  }

  Widget _castTab(AnimeDetail anime) {
    if (anime.cast.isEmpty) {
      return EmptyBlock(
        icon: HugeIcons.strokeRoundedUser,
        title: context.t('common:types.cast'),
      );
    }
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
      itemCount: anime.cast.length,
      itemBuilder: (context, index) {
        final member = anime.cast[index];
        return PersonTile(
          name: member.name,
          subtitle: member.positions.join(', '),
          imageUrl: malImage(member.imageUrl),
          onTap: member.slug == null ? null : () => _openPerson(member.slug!),
        );
      },
    );
  }

  Widget _charactersTab(AnimeDetail anime) {
    if (anime.characters.isEmpty) {
      return EmptyBlock(
        icon: HugeIcons.strokeRoundedUser,
        title: context.t('library:characters'),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: AdaptiveGridDelegate(
        context: context,
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: anime.characters.length,
      itemBuilder: (context, index) {
        final character = anime.characters[index];
        final actors = _primaryVoiceActors(character.voiceActors);
        return PersonTile(
          name: character.name,
          subtitle: character.role,
          imageUrl: malImage(character.imageUrl),
          footer: actors.isEmpty
              ? null
              : Column(
                  children: [
                    for (final actor in actors)
                      InkWell(
                        onTap: actor.slug == null
                            ? null
                            : () => _openPerson(actor.slug!),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '${actor.name}, ${actor.language}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: actor.slug == null
                                      ? Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                      : Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  List<AnimeVoiceActor> _primaryVoiceActors(List<AnimeVoiceActor> actors) {
    const preferred = ['Japanese', 'English'];
    final picked = [
      for (final language in preferred)
        ...actors.where((a) => a.language == language).take(1),
    ];
    return picked.isNotEmpty ? picked : actors.take(1).toList();
  }

  Widget _listsTab(AnimeDetail anime) {
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

  Widget _buildReviews(AnimeDetail anime) {
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
