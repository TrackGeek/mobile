import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../components/feed/feed_list.dart';
import '../components/feed/feed_tabs.dart';
import '../components/feed/tracking_header.dart';
import '../controllers/feed_controller.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/feed_entry.dart';
import '../models/media_type.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/media_detail_service.dart';
import '../services/person_service.dart';
import '../services/progress_service.dart';
import 'feed_composer_page.dart';
import 'media_detail_page.dart';
import 'person_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.progress,
    required this.details,
    required this.people,
    required this.favorites,
    required this.activities,
    required this.api,
    required this.session,
    required this.onOpenProfile,
    this.onOpenUserProfile,
    this.onOpenGenre,
    this.onOpenSettings,
  });

  final ProgressService progress;
  final MediaDetailService details;
  final PersonService people;
  final FavoriteService favorites;
  final ActivityService activities;
  final ApiClient api;
  final SessionController session;
  final VoidCallback onOpenProfile;
  final void Function(String username)? onOpenUserProfile;
  final void Function(MediaType type, String genre)? onOpenGenre;
  final VoidCallback? onOpenSettings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FeedKind _tab = FeedKind.following;
  final _controllers = <FeedKind, FeedController>{};

  FeedController _controllerFor(FeedKind kind) => _controllers.putIfAbsent(
    kind,
    () => FeedController(
      widget.activities,
      kind: kind,
      language: Localizations.localeOf(context).toLanguageTag(),
    )..ensureLoaded(),
  );

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setTab(FeedKind kind) {
    if (_tab == kind) return;
    setState(() => _tab = kind);
    _controllerFor(kind).ensureLoaded();
  }

  MediaDetailEnv get _env => (
    api: widget.api,
    session: widget.session,
    details: widget.details,
    people: widget.people,
    favorites: widget.favorites,
    progress: widget.progress,
    onOpenUser: _openUserName,
    onOpenGenre: widget.onOpenGenre,
    onOpenSettings: widget.onOpenSettings,
  );

  void _openUserName(String username) {
    if (username == widget.session.user?.username) {
      widget.onOpenProfile();
      return;
    }
    widget.onOpenUserProfile?.call(username);
  }

  void _openMedia(FeedMediaLink media) {
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
            onOpenUser: widget.onOpenUserProfile,
            onOpenGenre: widget.onOpenGenre,
            onOpenSettings: widget.onOpenSettings,
          ),
        ),
      );
      return;
    }
    final type = media.type;
    if (type == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: type,
          id: media.slug,
          details: widget.details,
          env: _env,
        ),
      ),
    );
  }

  void _openUser(FeedUserTitleLink link) {
    if (link.username == widget.session.user?.username) {
      widget.onOpenProfile();
      return;
    }
    widget.onOpenUserProfile?.call(link.username);
  }

  Future<void> _refresh() async {
    widget.progress.refresh();
    await _controllerFor(_tab).refresh();
  }

  Future<void> _updatePost(String postId, String content) async {
    await widget.activities.updatePost(postId, content: content);
    for (final controller in _controllers.values) {
      unawaited(controller.refresh());
    }
  }

  Future<void> _deletePost(String postId) async {
    await widget.activities.deletePost(postId);
    for (final controller in _controllers.values) {
      unawaited(controller.refresh());
    }
  }

  Future<void> _compose() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FeedComposerPage(
          api: widget.api,
          activities: widget.activities,
          session: widget.session,
        ),
      ),
    );
    if (published == true && mounted) {
      for (final controller in _controllers.values) {
        unawaited(controller.refresh());
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t('feed:postSuccess'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controllerFor(_tab);
    final userId = widget.session.user?.id ?? '';
    final (emptyTitle, emptyDescription) = switch (_tab) {
      FeedKind.following => (
        context.t('feed:emptyTitle'),
        context.t('feed:emptyFollowingDescription'),
      ),
      FeedKind.global => (
        context.t('feed:emptyTitle'),
        context.t('feed:emptyGlobalDescription'),
      ),
      FeedKind.trending => (
        context.t('feed:emptyTrendingTitle'),
        context.t('feed:emptyTrendingDescription'),
      ),
      FeedKind.user => (
        context.t('user:noActivity'),
        context.t('user:noActivityDescription'),
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: FeedList(
          key: ValueKey(_tab),
          controller: controller,
          session: widget.session,
          emptyTitle: emptyTitle,
          emptyDescription: emptyDescription,
          onRefresh: _refresh,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: FeedTabs(active: _tab, onChanged: _setTab),
              ),
              TrackingHeader(
                userId: userId,
                progress: widget.progress,
                details: widget.details,
                env: _env,
                onViewAll: widget.onOpenProfile,
              ),
            ],
          ),
          onOpenMedia: _openMedia,
          onOpenUser: _openUser,
          onUpdatePost: _updatePost,
          onDeletePost: _deletePost,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: context.t('feed:postPlaceholder'),
        onPressed: _compose,
        child: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01),
      ),
    );
  }
}
