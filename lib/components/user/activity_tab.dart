import 'package:flutter/material.dart';

import '../../controllers/feed_controller.dart';
import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../feed/feed_list.dart';

class UserActivityTab extends StatefulWidget {
  const UserActivityTab({
    super.key,
    required this.controller,
    required this.session,
    this.onOpenMedia,
    this.onOpenUser,
    this.onUpdatePost,
    this.onDeletePost,
  });

  final FeedController controller;
  final SessionController session;
  final void Function(FeedMediaLink media)? onOpenMedia;
  final void Function(FeedUserTitleLink user)? onOpenUser;
  final Future<void> Function(String postId, String content)? onUpdatePost;
  final Future<void> Function(String postId)? onDeletePost;

  @override
  State<UserActivityTab> createState() => _UserActivityTabState();
}

class _UserActivityTabState extends State<UserActivityTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FeedList(
      controller: widget.controller,
      session: widget.session,
      emptyTitle: context.t('user:noActivity'),
      emptyDescription: context.t('user:noActivityDescription'),
      onOpenMedia: widget.onOpenMedia,
      onOpenUser: widget.onOpenUser,
      onUpdatePost: widget.onUpdatePost,
      onDeletePost: widget.onDeletePost,
    );
  }
}
