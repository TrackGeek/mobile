import '../app/scrollable_tab.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../components/user/activity_tab.dart';
import '../components/user/favorites_tab.dart';
import '../components/user/follows_tab.dart';
import '../components/user/lists_tab.dart';
import '../components/user/missions_tab.dart';
import '../components/user/overview_tab.dart';
import '../components/user/profile_header.dart';
import '../components/user/profile_tabs.dart';
import '../components/user/profile_error.dart';
import '../components/user/progress_tab.dart';
import '../components/user/reviews_tab.dart';
import '../components/user/screenshots_tab.dart';
import '../controllers/feed_controller.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/favorite.dart';
import '../models/feed_entry.dart';
import '../models/follow.dart';
import '../models/media_type.dart';
import '../models/user_profile.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/game_service.dart';
import '../services/list_service.dart';
import '../services/media_detail_service.dart';
import '../services/person_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';
import 'media_detail_page.dart';
import 'person_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.session,
    required this.users,
    required this.progress,
    required this.favorites,
    required this.reviews,
    required this.lists,
    required this.comments,
    required this.games,
    required this.activities,
    required this.details,
    required this.people,
    required this.api,
    this.username,
    this.initialTab,
    this.onOpenShop,
    this.onOpenSettings,
    this.onSignedOut,
  });

  final SessionController session;
  final UserService users;
  final ProgressService progress;
  final FavoriteService favorites;
  final ReviewService reviews;
  final ListService lists;
  final CommentService comments;
  final GameService games;
  final ActivityService activities;
  final MediaDetailService details;
  final PersonService people;
  final ApiClient api;
  final String? username;
  final String? initialTab;
  final VoidCallback? onOpenShop;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSignedOut;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> implements ScrollableTab {
  final _scrolls = <String, ScrollController>{};

  ScrollController _scrollFor(String tab) =>
      _scrolls.putIfAbsent(tab, ScrollController.new);

  UserProfile? _user;
  FollowStatus? _followStatus;
  bool _loading = true;
  bool _followBusy = false;
  Object? _error;
  late String _tab = widget.initialTab ?? 'overview';
  MediaType? _progressType;
  FeedController? _activityController;

  bool get _isOwner =>
      widget.session.user?.id != null && widget.session.user?.id == _user?.id;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _activityController?.dispose();
    for (final c in _scrolls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void scrollToTop() {
    final scroller = _scrollFor(_tab);
    final atTop = !scroller.hasClients || scroller.offset <= 0;
    if (!atTop) {
      scroller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
  }

  String? get _username => widget.username ?? widget.session.user?.username;

  Future<void> _load() async {
    final username = _username;
    if (username == null || username.isEmpty) {
      setState(() {
        _error = const ApiException(ApiFailure.notFound);
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final language = L10nScope.of(context).language;
      final user = await widget.users.userByUsername(
        username,
        language: language,
      );
      if (!mounted) return;
      _progressType ??= user.latestProgressType ?? MediaType.game;
      _activityController ??= FeedController(
        widget.activities,
        kind: FeedKind.user,
        userId: user.id,
        language: language,
      );
      setState(() {
        _user = user;
        _loading = false;
      });
      unawaited(_loadFollowStatus(user));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadFollowStatus(UserProfile user) async {
    if (_isOwner || widget.session.user == null) {
      setState(() => _followStatus = null);
      return;
    }
    try {
      final status = await widget.users.followStatusDetails(
        user.username,
        language: L10nScope.of(context).language,
      );
      if (mounted) setState(() => _followStatus = status);
    } catch (_) {
      // follow button stays hidden behind last known state
    }
  }

  Future<void> _toggleFollow() async {
    final user = _user;
    final status = _followStatus;
    if (user == null || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      final language = L10nScope.of(context).language;
      if (status?.isFollowing == true) {
        await widget.users.unfollow(user.id, language: language);
      } else {
        await widget.users.follow(user.id, language: language);
      }
      await _load();
    } catch (_) {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  void _setTab(String tab) => setState(() => _tab = tab);

  void _openMedia(MediaType type, String slug) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: type,
          id: slug,
          details: widget.details,
          env: _env,
        ),
      ),
    );
  }

  MediaDetailEnv get _env => (
    api: widget.api,
    session: widget.session,
    details: widget.details,
    people: widget.people,
    favorites: widget.favorites,
    progress: widget.progress,
    onOpenUser: _openUser,
    onOpenGenre: null,
    onOpenSettings: widget.onOpenSettings,
  );

  void _openUser(String username) {
    if (username == _username) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          session: widget.session,
          users: widget.users,
          progress: widget.progress,
          favorites: widget.favorites,
          reviews: widget.reviews,
          lists: widget.lists,
          comments: widget.comments,
          games: widget.games,
          activities: widget.activities,
          details: widget.details,
          people: widget.people,
          api: widget.api,
          username: username,
          onOpenSettings: widget.onOpenSettings,
        ),
      ),
    );
  }

  void _openFeedMedia(FeedMediaLink media) {
    if (media.person) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonPage(
            request: PersonSlugRequest(media.slug),
            people: widget.people,
            details: widget.details,
            favorites: widget.favorites,
            session: widget.session,
            api: widget.api,
            onOpenUser: _openUser,
            onOpenSettings: widget.onOpenSettings,
          ),
        ),
      );
      return;
    }
    final type = media.type;
    if (type == null) return;
    _openMedia(type, media.slug);
  }

  void _openFeedUser(FeedUserTitleLink link) {
    if (link.username == widget.session.user?.username &&
        widget.username == null) {
      _setTab('overview');
      return;
    }
    _openUser(link.username);
  }

  Future<void> _updatePost(String postId, String content) async {
    await widget.activities.updatePost(postId, content: content);
    unawaited(_activityController?.refresh());
  }

  Future<void> _deletePost(String postId) async {
    await widget.activities.deletePost(postId);
    unawaited(_activityController?.refresh());
  }

  List<(String, String)> _tabs(UserProfile user) {
    String t(String key) => context.t(key);
    return [
      ('overview', t('user:overview')),
      ('activity', t('user:activity')),
      if (user.totalProgress > 0)
        ('progress', '${t('common:progress')} (${user.totalProgress})'),
      if (user.reviewCount > 0)
        ('reviews', '${t('common:reviews')} (${user.reviewCount})'),
      if (user.listCount > 0)
        ('lists', '${t('common:lists')} (${user.listCount})'),
      if (user.favoriteCount > 0)
        ('favorites', '${t('user:favorites')} (${user.favoriteCount})'),
      if (user.missionsTotal > 0)
        (
          'missions',
          '${t('missions:title')} (${user.missionsCompleted}/${user.missionsTotal})',
        ),
      if (user.screenshotCount > 0)
        ('screenshots', '${t('common:screenshots')} (${user.screenshotCount})'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final isNested = widget.username != null;
    return PrimaryScrollController(
      controller: _scrollFor(_tab),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            user == null ? context.t('common:profile') : '@${user.username}',
          ),
          actions: [
            if (widget.onOpenShop != null && _isOwner)
              IconButton(
                onPressed: widget.onOpenShop,
                tooltip: context.t('common:shop'),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedShoppingBag03,
                ),
              ),
            if (_isOwner) ...[
              IconButton(
                onPressed: widget.onOpenSettings,
                tooltip: context.t('app:tabs.settings'),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    unawaited(widget.session.signOut());
                    widget.onSignedOut?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(context.t('auth:logout')),
                  ),
                ],
              ),
            ],
            if (isNested)
              IconButton(
                onPressed: _load,
                tooltip: context.t('common:tryAgain'),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
              ),
          ],
        ),
        body: SafeArea(
          child: _loading && user == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && user == null
              ? ProfileError(
                  notFound:
                      _error is ApiException &&
                      (_error as ApiException).failure == ApiFailure.notFound,
                  onRetry: _load,
                )
              : user == null
              ? const SizedBox.shrink()
              : NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ProfileHeader(
                            user: user,
                            isOwner: _isOwner,
                            isAuthenticated: widget.session.user != null,
                            isFollowing: _followStatus?.isFollowing == true,
                            followsYou: _followStatus?.followsYou == true,
                            followBusy: _followBusy,
                            onFollow: _toggleFollow,
                            onEdit: widget.onOpenSettings,
                            onOpenFollowers: () => _setTab('followers'),
                            onOpenFollowing: () => _setTab('following'),
                          ),
                          const SizedBox(height: 12),
                          ProfileTabs(
                            tabs: _tabs(user),
                            active: _tab,
                            onSelect: _setTab,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                  body: _tabBody(user),
                ),
        ),
      ),
    );
  }

  Widget _tabBody(UserProfile user) {
    switch (_tab) {
      case 'activity':
        final controller = _activityController;
        if (controller == null) return const SizedBox.shrink();
        return UserActivityTab(
          key: ValueKey('activity-${user.id}'),
          controller: controller,
          session: widget.session,
          onOpenMedia: _openFeedMedia,
          onOpenUser: _openFeedUser,
          onUpdatePost: _updatePost,
          onDeletePost: _deletePost,
        );
      case 'progress':
        if (user.totalProgress <= 0) return _fallback(user);
        return UserProgressTab(
          key: ValueKey('progress-${user.id}'),
          userId: user.id,
          session: widget.session,
          progress: widget.progress,
          contentType: _progressType ?? MediaType.game,
          onContentTypeChange: (type) => _progressType = type,
          onOpenMedia: _openMedia,
        );
      case 'reviews':
        if (user.reviewCount <= 0) return _fallback(user);
        return UserReviewsTab(
          key: ValueKey('reviews-${user.id}'),
          userId: user.id,
          session: widget.session,
          reviews: widget.reviews,
          initialType: user.latestReviewType,
          onOpenMedia: _openMedia,
          onChanged: _load,
        );
      case 'lists':
        if (user.listCount <= 0) return _fallback(user);
        return UserListsTab(
          key: ValueKey('lists-${user.id}'),
          userId: user.id,
          session: widget.session,
          lists: widget.lists,
          isOwner: _isOwner,
          onOpenMedia: _openMedia,
          onChanged: _load,
        );
      case 'favorites':
        if (user.favoriteCount <= 0) return _fallback(user);
        return UserFavoritesTab(
          key: ValueKey('favorites-${user.id}'),
          userId: user.id,
          session: widget.session,
          favorites: widget.favorites,
          initialType: user.latestFavoriteType,
          onOpenItem: _openFavorite,
        );
      case 'missions':
        if (user.missionsTotal <= 0) return _fallback(user);
        return UserMissionsTab(
          key: ValueKey('missions-${user.id}'),
          userId: user.id,
          users: widget.users,
        );
      case 'screenshots':
        if (user.screenshotCount <= 0) return _fallback(user);
        return UserScreenshotsTab(
          key: ValueKey('screenshots-${user.id}'),
          userId: user.id,
          games: widget.games,
          onOpenGame: (igdbId) => _openMedia(MediaType.game, igdbId),
        );
      case 'followers':
        return UserFollowsTab(
          key: ValueKey('followers-${user.id}'),
          userId: user.id,
          kind: 'followers',
          session: widget.session,
          users: widget.users,
          onOpenUser: _openUser,
          onChanged: _load,
        );
      case 'following':
        return UserFollowsTab(
          key: ValueKey('following-${user.id}'),
          userId: user.id,
          kind: 'following',
          session: widget.session,
          users: widget.users,
          onOpenUser: _openUser,
          onChanged: _load,
        );
      case 'overview':
      default:
        return UserOverviewTab(
          key: ValueKey('overview-${user.id}'),
          user: user,
          session: widget.session,
          users: widget.users,
          favorites: widget.favorites,
          comments: widget.comments,
          games: widget.games,
          onSeeFavorites: () => _setTab('favorites'),
          onSeeProgress: (type) {
            _progressType = type;
            _setTab('progress');
          },
          onOpenMedia: _openMedia,
          onOpenUser: _openUser,
          onChanged: _load,
        );
    }
  }

  void _openFavorite(FavoriteItem item) {
    if (item.target == FavoriteTarget.person) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PersonPage(
            request: PersonSlugRequest(item.slug),
            people: widget.people,
            details: widget.details,
            favorites: widget.favorites,
            session: widget.session,
            api: widget.api,
            onOpenUser: _openUser,
            onOpenSettings: widget.onOpenSettings,
          ),
        ),
      );
      return;
    }
    final type = switch (item.target) {
      FavoriteTarget.anime => MediaType.anime,
      FavoriteTarget.manga => MediaType.manga,
      FavoriteTarget.tv => MediaType.tv,
      FavoriteTarget.movie => MediaType.movie,
      FavoriteTarget.game => MediaType.game,
      FavoriteTarget.book => MediaType.book,
      _ => null,
    };
    if (type != null) _openMedia(type, item.slug);
  }

  Widget _fallback(UserProfile user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _setTab('overview');
    });
    return const SizedBox.shrink();
  }
}
