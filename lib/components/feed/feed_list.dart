import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/feed_controller.dart';
import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import 'feed_item_card.dart';
import 'post_card.dart';
import 'screenshot_card.dart';
import '../layout/tg_refresh_indicator.dart';
import '../../utils/haptics.dart';

class FeedList extends StatefulWidget {
  const FeedList({
    super.key,
    required this.controller,
    required this.session,
    required this.emptyTitle,
    this.emptyDescription,
    this.header,
    this.onRefresh,
    this.onOpenMedia,
    this.onOpenUser,
    this.onUpdatePost,
    this.onDeletePost,
  });

  final FeedController controller;
  final SessionController session;
  final String emptyTitle;
  final String? emptyDescription;
  final Widget? header;
  final Future<void> Function()? onRefresh;
  final void Function(FeedMediaLink media)? onOpenMedia;
  final void Function(FeedUserTitleLink user)? onOpenUser;
  final Future<void> Function(String postId, String content)? onUpdatePost;
  final Future<void> Function(String postId)? onDeletePost;

  @override
  State<FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<FeedList> {
  Future<void> _react(
    FeedEntry entry,
    String emoji,
    FeedReaction? current,
  ) async {
    final user = widget.session.user;
    if (user == null) return;
    try {
      await widget.controller.react(
        entry,
        emoji,
        userId: user.id,
        username: user.username ?? user.name,
      );
    } catch (_) {
      if (mounted) {
        HapticsHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('feed:reactionError'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) {
          controller.loadMore();
        }
        return false;
      },
      child: TgRefreshIndicator(
        onRefresh: widget.onRefresh ?? controller.refresh,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final header = widget.header;
            final leading = header == null ? 0 : 1;
            if (!controller.loaded && controller.isLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [?header, const _FeedSkeleton()],
              );
            }
            if (controller.error != null && controller.entries.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ?header,
                  SizedBox(
                    height: 320,
                    child: _FeedError(onRetry: controller.load),
                  ),
                ],
              );
            }
            if (controller.entries.isEmpty && controller.loaded) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ?header,
                  SizedBox(
                    height: 320,
                    child: _FeedEmpty(
                      title: widget.emptyTitle,
                      description: widget.emptyDescription,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: header == null ? 8 : 0, bottom: 24),
              itemCount:
                  leading +
                  controller.entries.length +
                  (controller.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0 && header != null) return header;
                index -= leading;
                if (index >= controller.entries.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final entry = controller.entries[index];
                final mediaLink = entry.media;
                final titleLink = entry.titleLink;
                final currentUserId = widget.session.user?.id ?? '';
                void onReact(String emoji, FeedReaction? current) =>
                    _react(entry, emoji, current);
                final isReacting = controller.isReacting(entry);
                final onTitleTap = titleLink is FeedMediaTitleLink
                    ? () => widget.onOpenMedia?.call(
                        FeedMediaLink(
                          slug: titleLink.slug,
                          type: titleLink.type,
                          person: titleLink.person,
                        ),
                      )
                    : titleLink is FeedUserTitleLink
                    ? () => widget.onOpenUser?.call(titleLink)
                    : null;
                final onUserTap = entry.profile.username != null
                    ? () => widget.onOpenUser?.call(
                        FeedUserTitleLink(
                          username: entry.profile.username!,
                          tab: 'overview',
                        ),
                      )
                    : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: switch (entry.kind) {
                    FeedEntryKind.screenshot => ScreenshotCard(
                      entry: entry,
                      currentUserId: currentUserId,
                      onMediaTap: mediaLink != null
                          ? () => widget.onOpenMedia?.call(mediaLink)
                          : null,
                      onUserTap: onUserTap,
                      onTitleLinkTap: onTitleTap,
                      onReact: onReact,
                      isReacting: isReacting,
                    ),
                    FeedEntryKind.post => PostCard(
                      entry: entry,
                      currentUserId: currentUserId,
                      onMediaTap: mediaLink != null
                          ? () => widget.onOpenMedia?.call(mediaLink)
                          : null,
                      onUserTap: onUserTap,
                      onTitleLinkTap: onTitleTap,
                      onReact: onReact,
                      isReacting: isReacting,
                      onUpdate: widget.onUpdatePost,
                      onDelete: widget.onDeletePost,
                    ),
                    _ => FeedItemCard(
                      entry: entry,
                      currentUserId: currentUserId,
                      onMediaTap: mediaLink != null
                          ? () => widget.onOpenMedia?.call(mediaLink)
                          : null,
                      onUserTap: onUserTap,
                      onTitleLinkTap: onTitleTap,
                      onReact: onReact,
                      isReacting: isReacting,
                    ),
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: _SkeletonCard(theme: theme),
            ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 14,
                    width: 180,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 12,
                        width: 96,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedError extends StatelessWidget {
  const _FeedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 40),
          const SizedBox(height: 12),
          Text(
            context.t('common:somethingWentWrong'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.t('common:tryAgainLater'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onRetry,
            child: Text(context.t('common:tryAgain')),
          ),
        ],
      ),
    );
  }
}

class _FeedEmpty extends StatelessWidget {
  const _FeedEmpty({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedActivity01, size: 40),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
