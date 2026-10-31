import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../controllers/session_controller.dart';
import 'scrollable_tab.dart';
import '../components/layout/adaptive_navigation.dart';
import '../l10n/l10n_context.dart';
import '../models/media_type.dart';
import '../pages/home_page.dart';
import '../pages/media_detail_page.dart';
import '../pages/notifications_page.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/shop_page.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';
import '../services/game_service.dart';
import '../services/list_service.dart';
import '../services/media_detail_service.dart';
import '../services/notification_alerts.dart';
import '../services/notification_service.dart';
import '../services/person_service.dart';
import '../services/progress_service.dart';
import '../services/review_service.dart';
import '../services/search_service.dart';
import '../services/settings_service.dart';
import '../services/genre_service.dart';
import '../services/shop_service.dart';
import '../services/user_service.dart';
import '../utils/numbers.dart';

class TrackGeekShell extends StatefulWidget {
  const TrackGeekShell({
    super.key,
    required this.search,
    required this.details,
    required this.people,
    required this.favorites,
    required this.progress,
    required this.activities,
    required this.api,
    required this.session,
    required this.settings,
    required this.users,
    required this.reviews,
    required this.lists,
    required this.comments,
    required this.games,
    required this.genres,
    required this.shop,
    required this.notifications,
  });

  final SearchGateway search;
  final MediaDetailService details;
  final PersonService people;
  final FavoriteService favorites;
  final ProgressService progress;
  final ActivityService activities;
  final ApiClient api;
  final SessionController session;
  final SettingsService settings;
  final UserService users;
  final ReviewService reviews;
  final ListService lists;
  final CommentService comments;
  final GameService games;
  final GenreService genres;
  final ShopService shop;
  final NotificationService notifications;

  @override
  State<TrackGeekShell> createState() => _TrackGeekShellState();
}

class _TrackGeekShellState extends State<TrackGeekShell>
    with WidgetsBindingObserver {
  static const _profileTab = 3;

  int _tab = 0;
  final List<GlobalKey> _pageKeys = List.generate(4, (_) => GlobalKey());
  int _unread = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(NotificationAlerts.checkInterval, (_) {
      _refreshUnread();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshUnread();
  }

  Future<void> _refreshUnread() async {
    try {
      final count = await widget.notifications.unreadCount(
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() => _unread = count);
      unawaited(NotificationAlerts.markSeen(count));
    } catch (_) {
      // badge keeps last value
    }
  }

  void _openShop() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopPage(
          shop: widget.shop,
          session: widget.session,
          onOpenSettings: _openSettings,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsPage(
          session: widget.session,
          settings: widget.settings,
          auth: widget.session.authService,
          passkeySource: widget.session.passkeySource,
        ),
      ),
    );
  }

  void _openUser(String username) {
    if (username == widget.session.user?.username) {
      setState(() => _tab = _profileTab);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
          onOpenSettings: _openSettings,
        ),
      ),
    );
  }

  void _openMedia(MediaType type, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => mediaDetailPage(
          type: type,
          id: id,
          details: widget.details,
          env: (
            api: widget.api,
            session: widget.session,
            details: widget.details,
            people: widget.people,
            favorites: widget.favorites,
            progress: widget.progress,
            onOpenUser: _openUser,
            onOpenGenre: _openGenre,
            onOpenSettings: _openSettings,
          ),
        ),
      ),
    );
  }

  void _openGenre(MediaType type, String genre) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(
          search: widget.search,
          details: widget.details,
          people: widget.people,
          favorites: widget.favorites,
          session: widget.session,
          users: widget.users,
          genres: widget.genres,
          api: widget.api,
          initialKind: MediaSearchKind(type),
          initialFilters: {'genres': genre},
          onOpenUser: _openUser,
          onOpenSettings: _openSettings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigation(
      selectedIndex: _tab,
      onSelected: (index) {
        if (index == _tab) {
          (_pageKeys[index].currentState as ScrollableTab?)?.scrollToTop();
          return;
        }
        setState(() => _tab = index);
      },
      body: IndexedStack(
        index: _tab,
        children: [
          HomePage(
            key: _pageKeys[0],
            progress: widget.progress,
            details: widget.details,
            people: widget.people,
            favorites: widget.favorites,
            activities: widget.activities,
            api: widget.api,
            session: widget.session,
            onOpenProfile: () => setState(() => _tab = _profileTab),
            onOpenUserProfile: _openUser,
            onOpenGenre: _openGenre,
            onOpenSettings: _openSettings,
          ),
          SearchPage(
            key: _pageKeys[1],
            search: widget.search,
            details: widget.details,
            people: widget.people,
            favorites: widget.favorites,
            session: widget.session,
            users: widget.users,
            genres: widget.genres,
            api: widget.api,
            onOpenUser: _openUser,
            onOpenSettings: _openSettings,
          ),
          NotificationsPage(
            key: _pageKeys[2],
            notifications: widget.notifications,
            onOpenUser: _openUser,
            onOpenMedia: _openMedia,
            onUnreadChanged: (count) {
              setState(() => _unread = count);
              unawaited(NotificationAlerts.markSeen(count));
            },
          ),
          ProfilePage(
            key: _pageKeys[3],
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
            onOpenShop: _openShop,
            onOpenSettings: _openSettings,
          ),
        ],
      ),
      destinations: [
        NavigationDestination(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedHome01),
          label: context.t('app:tabs.home'),
        ),
        NavigationDestination(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
          label: context.t('app:tabs.search'),
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: _unread > 0,
            label: Text(_unread.humanizedCount()),
            child: const HugeIcon(icon: HugeIcons.strokeRoundedNotification01),
          ),
          label: context.t('common:notifications'),
        ),
        NavigationDestination(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedUser),
          label: context.t('common:profile'),
        ),
      ],
    );
  }
}
