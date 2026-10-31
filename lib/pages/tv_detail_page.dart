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
import '../components/details/media_carousel.dart';
import '../components/details/media_list_card.dart';
import '../components/details/people_cards.dart';
import '../components/details/refresh_data.dart';
import '../components/details/season_episode_progress.dart';
import '../components/details/season_episodes.dart';
import '../components/details/tracking.dart';
import '../components/details/tv_tracking_sheet.dart';
import '../components/details/watch_links_row.dart';
import '../components/details/watch_providers.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../components/user/comments_card.dart';
import '../components/user/star_rating.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/tv_detail.dart';
import '../models/user_list.dart';
import '../models/watch_link.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/list_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../services/tv_show_service.dart';
import '../utils/dates.dart';
import '../utils/episode_backfill.dart';
import '../utils/genres.dart';
import '../utils/release.dart';
import '../utils/social_links.dart';
import '../utils/status.dart';
import '../utils/watch_links.dart';
import '../utils/watch_time.dart';
import 'company_page.dart';
import 'media_detail_page.dart';
import 'person_page.dart';
import '../components/layout/edgy.dart';
import '../components/layout/tg_refresh_indicator.dart';
import '../utils/haptics.dart';
import '../utils/numbers.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = TgStatus.planning;
const _completedColor = TgStatus.completed;

class TvDetailPage extends StatefulWidget {
  const TvDetailPage({super.key, required this.tmdbId, required this.env});

  final String tmdbId;
  final MediaDetailEnv env;

  @override
  State<TvDetailPage> createState() => _TvDetailPageState();
}

class _TvDetailPageState extends State<TvDetailPage> {
  late final TvShowService _tv;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;
  late final CommentService _comments;
  late final SettingsService _settings;

  TvShowDetail? _show;
  List<TvSeason>? _seasons;
  var _seasonsFailed = false;
  var _loading = true;
  ApiException? _error;

  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;

  TvShowProgress? _progress;
  List<TvEpisodeWatch>? _episodeWatch;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];
  List<WatchLink> _watchLinks = const [];
  BackfillStore _backfill = BackfillStore.empty();

  var _statusBusy = false;
  var _episodeBusy = false;
  var _favoriteBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  bool get _unreleased =>
      isMediaUnreleased(MediaType.tv, status: _show?.status);

  String get _backfillKey => 'tv:${_show?.id}';

  List<SeasonWatchData> get _mySeasons => [
    for (final season in _seasons ?? const <TvSeason>[])
      if (season.numberOfEpisodes > 0)
        (
          seasonNumber: season.seasonNumber,
          totalEpisodes: season.numberOfEpisodes,
          watchedEpisodes: [
            for (final w in _episodeWatch ?? const <TvEpisodeWatch>[])
              if (w.season == season.seasonNumber && w.status == 'Completed')
                w.episode,
          ],
        ),
  ];

  ({int season, int episode}) get _nextWatch =>
      nextEpisodeFromSeasons(_mySeasons);

  double? get _remainingHours => remainingSeasonWatchHours(
    _mySeasons,
    episodeRuntimeMinutesFromValues(_show?.episodeRuntime ?? const []),
  );

  @override
  void initState() {
    super.initState();
    _tv = TvShowService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _comments = CommentService(widget.env.api);
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
      final show = await _tv.detail(
        int.parse(widget.tmdbId),
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _show = show;
        _loading = false;
      });
      unawaited(_loadSecondary(show));
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

  Future<void> _loadSecondary(TvShowDetail show) async {
    final language = L10nScope.of(context).language;
    unawaited(_loadSeasons());
    unawaited(
      _reviews
          .mediaReviews(MediaType.tv, mediaId: show.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.tv,
            mediaId: show.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _tv
            .progress(userId, show.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _tv
            .episodeWatch(userId, show.id)
            .then((v) => mounted ? setState(() => _episodeWatch = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.tv, show.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.tv, mediaId: show.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.tv,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.tv, mediaId: show.id)
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
                                watchLinkContentType[MediaType.tv],
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

  Future<void> _loadSeasons() async {
    final show = _show;
    if (show == null) return;
    try {
      final seasons = await _tv.seasons(
        show.tmdbId,
        language: L10nScope.of(context).language,
      );
      if (mounted) {
        setState(() {
          _seasons = seasons;
          _seasonsFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _seasonsFailed = true);
    }
  }

  Future<void> _reloadTracking() async {
    final show = _show;
    final userId = _userId;
    if (show == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _tv
        .progress(userId, show.id)
        .catchError((_) => _progress);
    final watch = await _tv
        .episodeWatch(userId, show.id)
        .catchError((_) => _episodeWatch ?? <TvEpisodeWatch>[]);
    final review = await _reviews
        .ownReview(MediaType.tv, mediaId: show.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.tv, mediaId: show.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.tv,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.tv,
        mediaId: show.id,
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
    final show = _show;
    if (show == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _tv.deleteProgress(current.id);
      } else {
        await _tv.saveProgress(
          show.id,
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
    final show = _show;
    if (show == null) return;
    if (current != null && current.status != 'Planning') return;
    try {
      await _tv.saveProgress(
        show.id,
        status: 'Watching',
        startedAt: DateTime.now().toIso8601String(),
      );
      await _reloadTracking();
    } catch (_) {}
  }

  Future<void> _toggleEpisode(int seasonNumber, int episode) async {
    final show = _show;
    if (show == null || _episodeBusy) return;
    final watched = {
      for (final s in _mySeasons)
        if (s.seasonNumber == seasonNumber) ...s.watchedEpisodes,
    };
    if (watched.contains(episode)) {
      await _runEpisodeOp(() async {
        await _tv.unwatchEpisode(show.id, seasonNumber, episode);
      });
      return;
    }
    final previous = unwatchedPreviousSeasonEpisodes(
      _mySeasons,
      seasonNumber,
      episode,
    );
    final target = (season: seasonNumber, episode: episode);
    final preference = _backfill.get(_backfillKey);
    if (previous.isEmpty || preference == BackfillPreference.never) {
      await _runEpisodeOp(() async {
        await _tv.watchEpisodes(show.id, [target]);
        await _startWatchingIfNeeded();
      });
      return;
    }
    if (preference == BackfillPreference.always) {
      await _runEpisodeOp(() async {
        await _tv.watchEpisodes(show.id, [...previous, target]);
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
          await _tv.watchEpisodes(show.id, [...previous, target]);
          await _startWatchingIfNeeded();
        });
      },
      onDecline: (remember) async {
        if (remember) {
          await _backfill.set(_backfillKey, BackfillPreference.never);
        }
        await _runEpisodeOp(() async {
          await _tv.watchEpisodes(show.id, [target]);
          await _startWatchingIfNeeded();
        });
      },
    );
  }

  Future<void> _toggleSeason(int seasonNumber, bool watched) async {
    final show = _show;
    if (show == null || _episodeBusy) return;
    final season = _mySeasons
        .where((s) => s.seasonNumber == seasonNumber)
        .firstOrNull;
    if (season == null) return;
    await _runEpisodeOp(() async {
      if (watched) {
        await _tv.watchEpisodes(show.id, [
          for (var e = 1; e <= season.totalEpisodes; e++)
            (season: seasonNumber, episode: e),
        ]);
        await _startWatchingIfNeeded();
      } else {
        for (final episode in season.watchedEpisodes) {
          await _tv.unwatchEpisode(show.id, seasonNumber, episode);
        }
      }
    });
    if (mounted) _toast('library:progressUpdated');
  }

  Future<void> _toggleAll(bool watched) async {
    final show = _show;
    if (show == null || _episodeBusy) return;
    await _runEpisodeOp(() async {
      if (watched) {
        await _tv.watchAll(show.id);
      } else {
        await _tv.unwatchAll(show.id);
      }
    });
    if (mounted) _toast('library:progressUpdated');
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
    final show = _show;
    if (show == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(FavoriteTarget.tv, show.id, _favorited ?? false);
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
    final show = _show;
    if (show == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _tv.refresh(show.tmdbId);
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
    final show = _show;
    if (show == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.tv,
        mediaId: show.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  void _openMoreOptions() {
    final show = _show;
    final userId = _userId;
    if (show == null || userId == null) return;
    TvTrackingSheet.open(
      context,
      tvShow: show,
      tvShowService: _tv,
      reviews: _reviews,
      lists: _lists,
      userId: userId,
      unreleased: _unreleased,
      progress: _progress,
      ownReview: _ownReview,
      episodeWatch: _episodeWatch ?? const [],
      seasons: _seasons ?? const [],
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

  void _openPerson(String? slug) {
    if (slug == null || slug.isEmpty) return;
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
          onOpenGenre: widget.env.onOpenGenre,
          onOpenSettings: widget.env.onOpenSettings,
        ),
      ),
    );
  }

  void _openCompany(int companyId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CompanyPage(type: MediaType.tv, id: '$companyId', env: widget.env),
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
    key == 'api:INTERNAL_SERVER_ERROR'
        ? HapticsHelper.error()
        : HapticsHelper.success();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t(key))));
  }

  @override
  Widget build(BuildContext context) {
    final show = _show;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          show?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (show != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/tv/${show.tmdbId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || show == null
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
                          _buildHeader(show),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(show),
                        const SizedBox(height: 32),
                        _buildReviews(show),
                      ],
                    );
                    return ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildSidebar(show)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          _buildHeader(show),
                          const SizedBox(height: 24),
                          _buildSidebar(show),
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

  List<PersonLink> _externalLinks(TvShowDetail show) {
    final external = show.external ?? const {};
    String? id(String key) {
      final value = external[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return [
      if (show.homepage?.isNotEmpty == true)
        PersonLink(
          key: 'homepage',
          href: show.homepage!,
          asset: '',
          label: show.homepage!,
        ),
      if (id('instagram_id') case final v?)
        PersonLink(
          key: 'instagram',
          href: 'https://instagram.com/$v',
          asset: 'assets/icons/social/instagram.svg',
          label: 'Instagram',
        ),
      if (id('facebook_id') case final v?)
        PersonLink(
          key: 'facebook',
          href: 'https://www.facebook.com/$v',
          asset: 'assets/icons/social/facebook.svg',
          label: 'Facebook',
        ),
      if (id('twitter_id') case final v?)
        PersonLink(
          key: 'x',
          href: 'https://x.com/$v',
          asset: 'assets/icons/social/x.svg',
          label: 'X',
        ),
      if (show.imdbId?.isNotEmpty == true)
        PersonLink(
          key: 'imdb',
          href: 'https://www.imdb.com/title/${show.imdbId}',
          asset: 'assets/icons/social/imdb.svg',
          label: 'IMDb',
        ),
    ];
  }

  Widget _buildSidebar(TvShowDetail show) {
    final release = formatDateRange(
      show.firstAirDate,
      show.lastAirDate,
      L10nScope.of(context).language,
      presentLabel: context.t('library:present'),
    );
    final links = _externalLinks(show);
    return DetailOverview(
      cover: CoverArt(url: show.posterUrl),
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
                  label: context.t('feed:lists.watching'),
                  icon: HugeIcons.strokeRoundedMonitorPlay,
                  color: Theme.of(context).colorScheme.primary,
                  isActive: _progress?.status == 'Watching',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Watching'),
                ),
              if (!_unreleased)
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
        if (show.status != null || release != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (show.status != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('common:status'),
                    value: statusLabel(context, show.status!),
                  ),
                ),
              if (show.status != null && release != null)
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
            lastRefreshedAt: show.lastRefreshedAt,
            sourceUrl: 'https://www.themoviedb.org/tv/${show.tmdbId}',
            sourceName: 'TMDB',
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

  Widget _buildHeader(TvShowDetail show) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    final showTimeLeft =
        _loggedIn &&
        _progress?.status == 'Watching' &&
        _episodeWatch != null &&
        _seasons != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          show.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (reviews != null && (reviews.total ?? 0) >= 1)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StarRating(value: show.tgReviewScore),
                  const SizedBox(width: 6),
                  Text(
                    show.tgReviewScore.toStringAsFixed(1),
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
            if (showTimeLeft) TimeLeft(hours: _remainingHours),
          ],
        ),
      ],
    );
  }

  List<String> _tabKeys() => ['info', 'episodes', 'cast', 'lists', 'comments'];

  Widget _buildTabs(TvShowDetail show) {
    final keys = _tabKeys();
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      ('episodes', context.t('library:episode_other')),
      ('cast', context.t('common:types.cast')),
      (
        'lists',
        '${context.t('common:lists')} (${(_containingLists?.total ?? 0).humanizedCount()})',
      ),
      ('comments', context.t('comments:title')),
    ];
    if (_tab >= tabs.length) _tab = 0;
    final selected = keys[_tab];
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
          'info' => _infoTab(show),
          'episodes' => _episodesTab(show),
          'cast' => _castTab(show),
          'lists' => _listsTab(show),
          _ => CommentsCard(
            target: (type: 'TVShow', id: show.id),
            comments: _comments,
            sessionUserId: _userId,
            canModerate: false,
            onOpenUser: widget.env.onOpenUser,
            showTitle: false,
          ),
        },
      ],
    );
  }

  Widget _infoTab(TvShowDetail show) {
    final theme = Theme.of(context);
    final stats = show.progressStats;
    final description = show.tagline?.trim().isNotEmpty == true
        ? show.tagline!.trim()
        : show.overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description?.isNotEmpty == true)
          Text(
            description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (show.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: show.genres,
              labelOf: (g) => genreLabel(context, g),
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.tv, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:tvShowCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(show))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
        if (_loggedIn && !_unreleased) ...[
          const SizedBox(height: 8),
          SeasonEpisodeProgress(
            seasons: _mySeasons,
            defaultSeason: _nextWatch.season,
            seasonCustomNames: {0: context.t('library:specials')},
            busy: _episodeBusy,
            onToggleEpisode: _toggleEpisode,
            onToggleSeason: _toggleSeason,
            onToggleAll: _toggleAll,
          ),
        ],
        const SizedBox(height: 8),
        WatchProvidersSection(
          providers: _tv.watchProviders,
          regions: _tv.watchProviderRegions,
          api: widget.env.api,
          session: widget.env.session,
          tmdbId: show.tmdbId,
        ),
        if (_watchLinks.isNotEmpty || widget.env.onOpenSettings != null) ...[
          const SizedBox(height: 12),
          CustomWatchLinks(
            links: _watchLinks,
            linkContext: WatchLinkContext(
              mediaType: MediaType.tv,
              imdbId: show.imdbId,
              tmdbId: show.tmdbId,
              title: show.name,
              season: _nextWatch.season,
              episode: _nextWatch.episode,
            ),
            onManage: widget.env.onOpenSettings,
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
                      '${stats.planToWatch.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.planToWatch.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.watching'),
                  icon: HugeIcons.strokeRoundedMonitorPlay,
                  color: Theme.of(context).colorScheme.primary,
                  percentage:
                      '${stats.watching.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.watching.count,
                  }),
                ),
                CommunityStatItem(
                  label: context.t('feed:lists.completed'),
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  color: theme.colorScheme.secondary,
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
        if (show.trailerId != null || show.backdrops.isNotEmpty) ...[
          const SizedBox(height: 16),
          MediaCarousel(
            title: show.name,
            trailerId: show.trailerId,
            backdrops: show.backdrops,
            onOpenUrl: _openUrl,
          ),
        ],
      ],
    );
  }

  List<Widget> _characteristicCards(TvShowDetail show) {
    final theme = Theme.of(context);
    Widget creatorNames() => Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (var i = 0; i < show.createdBy.length; i++) ...[
          if (i > 0) const Text(','),
          show.createdBy[i].slug != null
              ? InkWell(
                  onTap: () => _openPerson(show.createdBy[i].slug),
                  child: Text(
                    show.createdBy[i].name,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                )
              : Text(show.createdBy[i].name),
        ],
      ],
    );

    return [
      if (show.createdBy.isNotEmpty)
        InfoCard(
          title: context.t('library:creators'),
          icon: HugeIcons.strokeRoundedPenLine,
          description: creatorNames(),
        ),
      if (show.numberOfSeasons != null && show.numberOfSeasons! > 0)
        InfoCard(
          title: context.t('library:season_other'),
          icon: HugeIcons.strokeRoundedGridView,
          description: Text(show.numberOfSeasons!.humanizedCount()),
        ),
      if (show.numberOfEpisodes != null && show.numberOfEpisodes! > 0)
        InfoCard(
          title: context.t('library:totalEpisodes'),
          icon: HugeIcons.strokeRoundedTv01,
          description: Text(show.numberOfEpisodes!.humanizedCount()),
        ),
      if (show.originalLanguage?.isNotEmpty == true)
        InfoCard(
          title: context.t('common:language'),
          icon: HugeIcons.strokeRoundedLanguages,
          description: Text(show.originalLanguage!.toUpperCase()),
        ),
      if (show.productionCompanies.isNotEmpty)
        InfoCard(
          title: context.t('library:productionCompanies'),
          icon: HugeIcons.strokeRoundedBuilding03,
          description: ListWithMore(
            entries: [
              for (final company in show.productionCompanies)
                (label: company.name, onTap: () => _openCompany(company.id)),
            ],
          ),
        ),
      if (show.episodeRuntime.isNotEmpty && show.episodeRuntime.first > 0)
        InfoCard(
          title: context.t('library:runtime'),
          icon: HugeIcons.strokeRoundedClock01,
          description: Text('${show.episodeRuntime.first} min'),
        ),
      if (show.type?.isNotEmpty == true)
        InfoCard(
          title: context.t('library:type'),
          icon: HugeIcons.strokeRoundedFileType,
          description: Text(show.type!),
        ),
    ];
  }

  Widget _episodesTab(TvShowDetail show) {
    final seasons = _seasons;
    if (seasons == null && !_seasonsFailed) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_seasonsFailed) {
      return DetailErrorState(onRetry: _loadSeasons);
    }
    return SeasonEpisodesSection(
      key: ValueKey('${show.id}:${show.lastRefreshedAt}'),
      seasons: seasons ?? const [],
      loadEpisodes: (seasonNumber) => _tv.seasonEpisodes(
        show.tmdbId,
        seasonNumber,
        language: L10nScope.of(context).language,
      ),
      initialSeason: _nextWatch.season,
    );
  }

  Widget _castTab(TvShowDetail show) {
    if (show.cast.isEmpty) {
      return EmptyBlock(
        icon: HugeIcons.strokeRoundedUser,
        title: context.t('common:noResults'),
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
      itemCount: show.cast.length,
      itemBuilder: (context, index) {
        final member = show.cast[index];
        return PersonTile(
          name: member.name,
          subtitle: member.character,
          imageUrl: member.profileUrl,
          onTap: member.slug == null ? null : () => _openPerson(member.slug),
        );
      },
    );
  }

  Widget _listsTab(TvShowDetail show) {
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

  Widget _buildReviews(TvShowDetail show) {
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
