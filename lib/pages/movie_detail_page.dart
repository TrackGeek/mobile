import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/details/community_stats.dart';
import '../components/details/detail_overview.dart';
import '../components/details/detail_review_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/details/external_links_row.dart';
import '../components/details/genre_pills.dart';
import '../components/details/media_carousel.dart';
import '../components/details/media_list_card.dart';
import '../components/details/movie_tracking_sheet.dart';
import '../components/details/people_cards.dart';
import '../components/details/refresh_data.dart';
import '../components/details/tracking.dart';
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
import '../models/movie_detail.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/user_list.dart';
import '../models/watch_link.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/list_service.dart';
import '../services/movie_service.dart';
import '../services/review_service.dart';
import '../services/settings_service.dart';
import '../utils/dates.dart';
import '../utils/genres.dart';
import '../utils/release.dart';
import '../utils/slug.dart';
import '../utils/social_links.dart';
import '../utils/status.dart';
import '../utils/watch_links.dart';
import 'company_page.dart';
import 'media_detail_page.dart';
import 'movie_franchise_page.dart';
import 'person_page.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = Color(0xFF9C4EDD);
const _completedColor = Color(0xFFE3A008);
const _chartFiveColor = Color(0xFFE5484D);

class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({super.key, required this.tmdbId, required this.env});

  final String tmdbId;
  final MediaDetailEnv env;

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late final MovieService _movies;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;
  late final CommentService _comments;
  late final SettingsService _settings;

  MovieDetail? _movie;
  var _loading = true;
  ApiException? _error;

  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;

  MovieProgress? _progress;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];
  List<WatchLink> _watchLinks = const [];

  var _statusBusy = false;
  var _favoriteBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  bool get _unreleased =>
      isMediaUnreleased(MediaType.movie, status: _movie?.status);

  @override
  void initState() {
    super.initState();
    _movies = MovieService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _comments = CommentService(widget.env.api);
    _settings = SettingsService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.of(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final movie = await _movies.detail(
        int.parse(widget.tmdbId),
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _movie = movie;
        _loading = false;
      });
      unawaited(_loadSecondary(movie));
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

  Future<void> _loadSecondary(MovieDetail movie) async {
    final language = L10nScope.of(context).language;
    unawaited(
      _reviews
          .mediaReviews(MediaType.movie, mediaId: movie.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.movie,
            mediaId: movie.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _movies
            .progress(userId, movie.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.movie, movie.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.movie, mediaId: movie.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.movie,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.movie, mediaId: movie.id)
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
                                watchLinkContentType[MediaType.movie],
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

  Future<void> _reloadTracking() async {
    final movie = _movie;
    final userId = _userId;
    if (movie == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _movies
        .progress(userId, movie.id)
        .catchError((_) => _progress);
    final review = await _reviews
        .ownReview(MediaType.movie, mediaId: movie.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.movie, mediaId: movie.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.movie,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.movie,
        mediaId: movie.id,
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
    final movie = _movie;
    if (movie == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _movies.deleteProgress(current.id);
      } else {
        await _movies.saveProgress(movie.id, status: status);
      }
      await _reloadTracking();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final movie = _movie;
    if (movie == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(
        FavoriteTarget.movie,
        movie.id,
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
    final movie = _movie;
    if (movie == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _movies.refresh(movie.tmdbId);
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
    final movie = _movie;
    if (movie == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.movie,
        mediaId: movie.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  void _openMoreOptions() {
    final movie = _movie;
    final userId = _userId;
    if (movie == null || userId == null) return;
    MovieTrackingSheet.open(
      context,
      movie: movie,
      movieService: _movies,
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
        builder: (_) => CompanyPage(
          type: MediaType.movie,
          id: '$companyId',
          env: widget.env,
        ),
      ),
    );
  }

  void _openFranchise(MovieCollectionRef collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieFranchisePage(
          slug: franchiseSlug(collection.id, collection.name),
          env: widget.env,
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

  List<String> _tabKeys() => ['info', 'cast', 'lists', 'comments'];

  @override
  Widget build(BuildContext context) {
    final movie = _movie;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          movie?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (movie != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/movie/${movie.tmdbId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || movie == null
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
                          _buildHeader(movie),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(movie),
                        const SizedBox(height: 32),
                        _buildReviews(movie),
                      ],
                    );
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 300, child: _buildSidebar(movie)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          _buildHeader(movie),
                          const SizedBox(height: 24),
                          _buildSidebar(movie),
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

  List<PersonLink> _externalLinks(MovieDetail movie) {
    final external = movie.external ?? const {};
    String? id(String key) {
      final value = external[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return [
      if (movie.homepage?.isNotEmpty == true)
        PersonLink(
          key: 'homepage',
          href: movie.homepage!,
          asset: '',
          label: movie.homepage!,
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
      if (movie.imdbId?.isNotEmpty == true)
        PersonLink(
          key: 'imdb',
          href: 'https://www.imdb.com/title/${movie.imdbId}',
          asset: 'assets/icons/social/imdb.svg',
          label: 'IMDb',
        ),
    ];
  }

  Widget _buildSidebar(MovieDetail movie) {
    final release = formatLongDate(
      movie.releaseDate,
      L10nScope.of(context).language,
    );
    final links = _externalLinks(movie);
    return DetailOverview(
      cover: CoverArt(url: movie.posterUrl),
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
                  label: context.t('feed:lists.completed'),
                  icon: HugeIcons.strokeRoundedCheckmarkSquare02,
                  color: _completedColor,
                  isActive: _progress?.status == 'Completed',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Completed'),
                ),
              if (!_unreleased)
                StatusButtonConfig(
                  label: context.t('feed:lists.dropped'),
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: _chartFiveColor,
                  isActive: _progress?.status == 'Dropped',
                  disabled: _statusBusy,
                  onTap: () => _setStatus('Dropped'),
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
        if (movie.status != null || release != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (movie.status != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('common:status'),
                    value: statusLabel(context, movie.status!),
                  ),
                ),
              if (movie.status != null && release != null)
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
            lastRefreshedAt: movie.lastRefreshedAt,
            sourceUrl: 'https://www.themoviedb.org/movie/${movie.tmdbId}',
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

  Widget _buildHeader(MovieDetail movie) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    final collection = movie.belongsToCollection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (collection != null && collection.name.isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _openFranchise(collection),
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
                    collection.name,
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
              StarRating(value: movie.tgReviewScore),
              const SizedBox(width: 6),
              Text(
                movie.tgReviewScore.toStringAsFixed(1),
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

  Widget _buildTabs(MovieDetail movie) {
    final keys = _tabKeys();
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      ('cast', context.t('common:types.cast')),
      (
        'lists',
        '${context.t('common:lists')} (${_containingLists?.total ?? 0})',
      ),
      ('comments', context.t('comments:title')),
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
          'info' => _infoTab(movie),
          'cast' => _castTab(movie),
          'lists' => _listsTab(movie),
          _ => CommentsCard(
            target: (type: 'Movie', id: movie.id),
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

  Widget _infoTab(MovieDetail movie) {
    final theme = Theme.of(context);
    final stats = movie.progressStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (movie.overview?.isNotEmpty == true)
          Text(
            movie.overview!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (movie.genres.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: movie.genres,
              labelOf: (g) => genreLabel(context, g),
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.movie, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:movieCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(movie))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
        const SizedBox(height: 8),
        WatchProvidersSection(
          providers: _movies.watchProviders,
          regions: _movies.watchProviderRegions,
          api: widget.env.api,
          session: widget.env.session,
          tmdbId: movie.tmdbId,
        ),
        if (_watchLinks.isNotEmpty || widget.env.onOpenSettings != null) ...[
          const SizedBox(height: 12),
          CustomWatchLinks(
            links: _watchLinks,
            linkContext: WatchLinkContext(
              mediaType: MediaType.movie,
              imdbId: movie.imdbId,
              tmdbId: movie.tmdbId,
              title: movie.title,
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
                  label: context.t('feed:lists.paused'),
                  icon: HugeIcons.strokeRoundedPauseCircle,
                  color: _chartFiveColor,
                  percentage: '${stats.paused.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.paused.count,
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
        if (movie.trailerId != null || movie.backdrops.isNotEmpty) ...[
          const SizedBox(height: 16),
          MediaCarousel(
            title: movie.title,
            trailerId: movie.trailerId,
            backdrops: movie.backdrops,
            onOpenUrl: _openUrl,
          ),
        ],
      ],
    );
  }

  List<Widget> _characteristicCards(MovieDetail movie) {
    final theme = Theme.of(context);
    final currency = NumberFormat.simpleCurrency(locale: 'en_US', name: 'USD');
    Widget directorNames() => Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        for (var i = 0; i < movie.directors.length; i++) ...[
          if (i > 0) const Text(','),
          movie.directors[i].slug != null
              ? InkWell(
                  onTap: () => _openPerson(movie.directors[i].slug),
                  child: Text(
                    movie.directors[i].name,
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                )
              : Text(movie.directors[i].name),
        ],
      ],
    );

    return [
      if (movie.directors.isNotEmpty)
        InfoCard(
          title: context.t('library:directors'),
          icon: HugeIcons.strokeRoundedClapperboard,
          description: directorNames(),
        ),
      if (movie.budget > 0)
        InfoCard(
          title: context.t('library:budget'),
          icon: HugeIcons.strokeRoundedPiggyBank,
          description: Text(currency.format(movie.budget)),
        ),
      if (movie.revenue > 0)
        InfoCard(
          title: context.t('library:revenue'),
          icon: HugeIcons.strokeRoundedTicket02,
          description: Text(currency.format(movie.revenue)),
        ),
      if (movie.spokenLanguages.isNotEmpty &&
          movie.spokenLanguages.first.name.isNotEmpty)
        InfoCard(
          title: context.t('common:language'),
          icon: HugeIcons.strokeRoundedLanguages,
          description: Text(movie.spokenLanguages.first.name),
        ),
      if (movie.productionCompanies.isNotEmpty)
        InfoCard(
          title: context.t('library:productionCompanies'),
          icon: HugeIcons.strokeRoundedBuilding03,
          description: ListWithMore(
            entries: [
              for (final company in movie.productionCompanies)
                (label: company.name, onTap: () => _openCompany(company.id)),
            ],
          ),
        ),
      if (movie.runtime != null && movie.runtime! > 0)
        InfoCard(
          title: context.t('library:runtime'),
          icon: HugeIcons.strokeRoundedClock01,
          description: Text('${movie.runtime} min'),
        ),
    ];
  }

  Widget _castTab(MovieDetail movie) {
    if (movie.cast.isEmpty) {
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
      itemCount: movie.cast.length,
      itemBuilder: (context, index) {
        final member = movie.cast[index];
        return PersonTile(
          name: member.name,
          subtitle: member.character,
          imageUrl: member.profileUrl,
          onTap: member.slug == null ? null : () => _openPerson(member.slug),
        );
      },
    );
  }

  Widget _listsTab(MovieDetail movie) {
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

  Widget _buildReviews(MovieDetail movie) {
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
