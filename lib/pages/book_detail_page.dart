import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../styles/tg_theme.dart';
import '../components/details/book_tracking_sheet.dart';
import '../components/details/community_stats.dart';
import '../components/details/detail_overview.dart';
import '../components/details/detail_review_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/details/editions_section.dart';
import '../components/details/genre_pills.dart';
import '../components/details/media_list_card.dart';
import '../components/details/refresh_data.dart';
import '../components/details/tracking.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../components/user/comments_card.dart';
import '../components/user/star_rating.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/book_detail.dart';
import '../models/feed_entry.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import '../models/user_list.dart';
import '../services/book_service.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/list_service.dart';
import '../services/review_service.dart';
import '../utils/dates.dart';
import '../utils/genres.dart';
import '../utils/release.dart';
import '../utils/slug.dart';
import 'book_franchise_page.dart';
import 'media_detail_page.dart';
import '../components/layout/edgy.dart';
import '../components/layout/tg_refresh_indicator.dart';
import '../utils/haptics.dart';
import '../utils/numbers.dart';
import '../components/layout/bottom_padding.dart';

const _siteUrl = 'https://trackgeek.net';
const _planningColor = TgStatus.planning;
const _readingColor = TgStatus.active;
const _completedColor = TgStatus.completed;

class BookDetailPage extends StatefulWidget {
  const BookDetailPage({
    super.key,
    required this.hardcoverId,
    required this.env,
  });

  final String hardcoverId;
  final MediaDetailEnv env;

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  late final BookService _books;
  late final FavoriteService _favorites;
  late final ReviewService _reviews;
  late final ListService _lists;
  late final CommentService _comments;

  BookDetail? _book;
  var _loading = true;
  ApiException? _error;

  PaginatedPage<UserReview>? _reviewsPage;
  PaginatedPage<UserList>? _containingLists;

  BookProgress? _progress;
  bool? _favorited;
  UserReview? _ownReview;
  List<UserList> _userLists = const [];
  List<String> _listStatus = const [];

  var _statusBusy = false;
  var _favoriteBusy = false;
  var _coverBusy = false;
  var _refreshing = false;
  String? _reactingReview;
  var _tab = 0;
  final Map<int, GlobalKey> _chipKeys = {};

  bool get _loggedIn => widget.env.session.loggedIn;

  String? get _userId => widget.env.session.user?.id;

  bool get _unreleased => isMediaUnreleased(
    MediaType.book,
    releaseDate: _book?.releaseDate,
    releaseYear: _book?.releaseYear,
  );

  @override
  void initState() {
    super.initState();
    _books = BookService(widget.env.api);
    _favorites = FavoriteService(widget.env.api);
    _reviews = ReviewService(widget.env.api);
    _lists = ListService(widget.env.api);
    _comments = CommentService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.read(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final book = await _books.detail(widget.hardcoverId, language: language);
      await ensureDateLocale(language);
      if (!mounted) return;
      setState(() {
        _book = book;
        _loading = false;
      });
      unawaited(_loadSecondary(book));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  Future<void> _loadSecondary(BookDetail book) async {
    final language = L10nScope.of(context).language;
    unawaited(
      _reviews
          .mediaReviews(MediaType.book, mediaId: book.id, language: language)
          .then((v) => mounted ? setState(() => _reviewsPage = v) : null)
          .catchError((_) {}),
    );
    unawaited(
      _lists
          .containingLists(
            MediaType.book,
            mediaId: book.id,
            itemsPerPage: 50,
            language: language,
          )
          .then((v) => mounted ? setState(() => _containingLists = v) : null)
          .catchError((_) {}),
    );
    if (_loggedIn) {
      final userId = _userId!;
      unawaited(
        _books
            .progress(userId, book.id)
            .then((v) => mounted ? setState(() => _progress = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _favorites
            .status(FavoriteTarget.book, book.id)
            .then((v) => mounted ? setState(() => _favorited = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _reviews
            .ownReview(MediaType.book, mediaId: book.id, userId: userId)
            .then((v) => mounted ? setState(() => _ownReview = v) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .userLists(
              userId,
              type: MediaType.book,
              itemsPerPage: 50,
              language: language,
            )
            .then((v) => mounted ? setState(() => _userLists = v.items) : null)
            .catchError((_) {}),
      );
      unawaited(
        _lists
            .listStatus(MediaType.book, mediaId: book.id)
            .then((v) => mounted ? setState(() => _listStatus = v) : null)
            .catchError((_) {}),
      );
    }
  }

  Future<void> _reloadTracking() async {
    final book = _book;
    final userId = _userId;
    if (book == null || userId == null || !_loggedIn) return;
    final language = L10nScope.of(context).language;
    final progress = await _books
        .progress(userId, book.id)
        .catchError((_) => _progress);
    final review = await _reviews
        .ownReview(MediaType.book, mediaId: book.id, userId: userId)
        .catchError((_) => _ownReview);
    final listStatus = await _lists
        .listStatus(MediaType.book, mediaId: book.id)
        .catchError((_) => _listStatus);
    final userLists = await _lists
        .userLists(
          userId,
          type: MediaType.book,
          itemsPerPage: 50,
          language: language,
        )
        .then((p) => p.items)
        .catchError((_) => _userLists);
    PaginatedPage<UserList>? containing;
    try {
      containing = await _lists.containingLists(
        MediaType.book,
        mediaId: book.id,
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
    final book = _book;
    if (book == null || _statusBusy || !_loggedIn) return;
    setState(() => _statusBusy = true);
    try {
      final current = _progress;
      if (current != null && current.status == status) {
        await _books.deleteProgress(current.id);
      } else {
        await _books.saveProgress(
          book.id,
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
    final book = _book;
    if (book == null || _favoriteBusy || !_loggedIn) return;
    setState(() => _favoriteBusy = true);
    try {
      await _favorites.toggle(
        FavoriteTarget.book,
        book.id,
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
    final book = _book;
    if (book == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      await _books.refresh(book.hardcoverId);
      await _load();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _setCover(int editionId) async {
    final book = _book;
    if (book == null || _coverBusy) return;
    setState(() => _coverBusy = true);
    try {
      await _books.setCover(book.hardcoverId, editionId);
      _toast('library:coverUpdated');
      await _load();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
      if (mounted) setState(() => _coverBusy = false);
    }
  }

  Future<void> _resetCover() async {
    final book = _book;
    if (book == null || _coverBusy) return;
    setState(() => _coverBusy = true);
    try {
      await _books.resetCover(book.hardcoverId);
      _toast('library:coverUpdated');
      await _load();
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
      if (mounted) setState(() => _coverBusy = false);
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
    final book = _book;
    if (book == null) return;
    PaginatedPage<UserReview>? page;
    try {
      page = await _reviews.mediaReviews(
        MediaType.book,
        mediaId: book.id,
        language: L10nScope.of(context).language,
      );
    } catch (_) {
      page = _reviewsPage;
    }
    if (mounted) setState(() => _reviewsPage = page);
  }

  void _openMoreOptions() {
    final book = _book;
    final userId = _userId;
    if (book == null || userId == null) return;
    BookTrackingSheet.open(
      context,
      book: book,
      bookService: _books,
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

  void _openFranchise(BookSeriesEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookFranchisePage(
          slug: franchiseSlug(entry.series.id, entry.series.name),
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
    final book = _book;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          book?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (book != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/book/${book.hardcoverId}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || book == null
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
                          _buildHeader(book),
                          const SizedBox(height: 24),
                        ],
                        _buildTabs(book, inset),
                        const SizedBox(height: 32),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: inset),
                          child: _buildReviews(book),
                        ),
                      ],
                    );
                    return ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                              SizedBox(width: 300, child: _buildSidebar(book)),
                              const SizedBox(width: 32),
                              Expanded(child: content),
                            ],
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildHeader(book),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildSidebar(book),
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

  Widget _buildSidebar(BookDetail book) {
    final release =
        formatLongDate(book.releaseDate, L10nScope.of(context).language) ??
        book.releaseYear?.toString();
    return DetailOverview(
      cover: CoverArt(url: book.imageUrl),
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
                  color: _readingColor,
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
        if (book.numberOfPages != null || release != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (book.numberOfPages != null)
                Expanded(
                  child: MetaStatCard(
                    label: context.t('library:page_other'),
                    value: book.numberOfPages!.humanizedCount(),
                  ),
                ),
              if (book.numberOfPages != null && release != null)
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
            lastRefreshedAt: book.lastRefreshedAt,
            sourceUrl: 'https://hardcover.app/books/${book.slug}',
            pending: _refreshing,
            onRefresh: _refreshData,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BookDetail book) {
    final theme = Theme.of(context);
    final reviews = _reviewsPage;
    final pages = book.numberOfPages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (book.bookSeries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBook02,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  children: [
                    for (var i = 0; i < book.bookSeries.length; i++) ...[
                      if (i > 0)
                        Text(
                          ', ',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      InkWell(
                        onTap: () => _openFranchise(book.bookSeries[i]),
                        child: Text(
                          book.bookSeries[i].position != null
                              ? '${book.bookSeries[i].series.name} #${book.bookSeries[i].positionLabel}'
                              : book.bookSeries[i].series.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
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
                  StarRating(value: book.tgReviewScore),
                  const SizedBox(width: 6),
                  Text(
                    book.tgReviewScore.toStringAsFixed(1),
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
            if (pages != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedChartBarLine,
                    size: 17,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${context.t('library:medium')}: '
                    '${context.t('common:dayCount', {'count': (pages / 29).round()})}',
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

  Widget _buildTabs(BookDetail book, double inset) {
    final tabs = <(String, String)>[
      ('info', context.t('library:info')),
      if (book.editions.isNotEmpty)
        (
          'editions',
          '${context.t('library:editions')} (${(book.editionsCount ?? book.editions.length).humanizedCount()})',
        ),
      (
        'lists',
        '${context.t('common:lists')} (${(_containingLists?.total ?? 0).humanizedCount()})',
      ),
      ('comments', context.t('comments:title')),
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
            'info' => _infoTab(book),
            'editions' => EditionsSection(
              editions: book.editions,
              title: book.title,
              coverEditionId: book.coverEditionId,
              customCoverEditionId: book.customCoverEditionId,
              canCustomize: _loggedIn,
              busy: _coverBusy,
              onUseCover: _setCover,
              onResetCover: _resetCover,
            ),
            'lists' => _listsTab(book),
            _ => CommentsCard(
              target: (type: 'Book', id: book.id),
              comments: _comments,
              sessionUserId: _userId,
              canModerate: false,
              onOpenUser: widget.env.onOpenUser,
              showTitle: false,
            ),
          },
        ),
      ],
    );
  }

  Widget _infoTab(BookDetail book) {
    final theme = Theme.of(context);
    final stats = book.progressStats;
    final knownBookGenres = staticGenres[MediaType.book] ?? const [];
    final tags = [
      for (final tag in book.taggings)
        if (knownBookGenres.contains(tag)) tag,
    ];
    final edition = book.primaryEdition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (book.description != null && book.description!.isNotEmpty)
          Text(
            book.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          DetailSection(
            title: context.t('library:genres'),
            child: GenrePills(
              genres: tags,
              labelOf: (g) => genreLabel(context, g),
              onOpen: widget.env.onOpenGenre == null
                  ? null
                  : (g) => widget.env.onOpenGenre!(MediaType.book, g),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DetailSection(
          title: context.t('library:bookCharacteristics'),
          child: Column(
            children: [
              for (final card in _characteristicCards(book, edition))
                Padding(padding: const EdgeInsets.only(bottom: 8), child: card),
            ],
          ),
        ),
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
                      '${stats.planToRead.percentage.toStringAsFixed(0)}%',
                  count: context.t('common:userCount', {
                    'count': stats.planToRead.count,
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

  List<Widget> _characteristicCards(BookDetail book, BookEdition? edition) {
    return [
      if (book.authors.isNotEmpty)
        InfoCard(
          title: context.t('library:authors'),
          icon: HugeIcons.strokeRoundedPencil,
          description: Text(book.authors.join(', ')),
        ),
      if (book.category != null)
        InfoCard(
          title: context.t('library:category'),
          icon: HugeIcons.strokeRoundedBook02,
          description: Text(book.category!),
        ),
      if (edition?.publisher != null)
        InfoCard(
          title: context.t('library:publisher'),
          icon: HugeIcons.strokeRoundedNotebook,
          description: Text(edition!.publisher!),
        ),
      if (edition?.language != null)
        InfoCard(
          title: context.t('common:language'),
          icon: HugeIcons.strokeRoundedLanguageSkill,
          description: Text(edition!.language!),
        ),
    ];
  }

  Widget _listsTab(BookDetail book) {
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

  Widget _buildReviews(BookDetail book) {
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
