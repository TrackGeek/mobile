import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import 'feed_icons.dart';
import 'feed_reactions.dart';
import 'feed_title.dart';

class FeedItemCard extends StatelessWidget {
  const FeedItemCard({
    super.key,
    required this.entry,
    required this.currentUserId,
    this.onMediaTap,
    this.onUserTap,
    this.onTitleLinkTap,
    this.onReact,
    this.isReacting = false,
    this.isReactionError = false,
  });

  final FeedEntry entry;
  final String currentUserId;
  final VoidCallback? onMediaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onTitleLinkTap;
  final void Function(String emoji, FeedReaction? currentReaction)? onReact;
  final bool isReacting;
  final bool isReactionError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeedCover(
              coverUrl: entry.coverUrl,
              mediaTitle: entry.mediaTitle,
              activityType: entry.activityType,
              isAdult: entry.isAdult,
              onTap: onMediaTap,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onUserTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FeedAvatar(
                              name: entry.profile.name,
                              avatarUrl: entry.profile.avatarUrl,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                entry.profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FeedTitle(
                      titleKey: entry.titleKey,
                      values: entry.titleValues,
                      onLinkTap: onTitleLinkTap,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Tooltip(
                            message: DateFormat.yMMMMd(locale)
                                .add_jm()
                                .format(entry.time.toLocal()),
                            child: Text(
                              DateFormat.yMd(locale)
                                  .add_jm()
                                  .format(entry.time.toLocal()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        FeedReactions(
                          currentUserId: currentUserId,
                          activityId: entry.activityId,
                          reactions: entry.reactions,
                          likes: entry.likes,
                          onReact: onReact,
                          isReacting: isReacting,
                          isError: isReactionError,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedCover extends StatelessWidget {
  const FeedCover({
    super.key,
    required this.coverUrl,
    this.mediaTitle,
    required this.activityType,
    this.isAdult = false,
    this.onTap,
    this.width = 84,
  });

  final String coverUrl;
  final String? mediaTitle;
  final String activityType;
  final bool isAdult;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon =
        feedActivityIcons[activityType] ?? HugeIcons.strokeRoundedActivity01;
    Widget child = Container(
      width: width,
      color: theme.colorScheme.surfaceContainerHigh,
      child: coverUrl.isEmpty
          ? Center(
              child: HugeIcon(
                icon: icon,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Opacity(
                    opacity: 0.6,
                    child: Transform.scale(
                      scale: 1.25,
                      child: Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Container(
                  color: theme.colorScheme.surface.withValues(alpha: 0.3),
                ),
                Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: HugeIcon(
                                icon: icon,
                                size: 24,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isAdult)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedViewOff,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
    );
    if (onTap != null) {
      child = InkWell(onTap: onTap, child: child);
    }
    return child;
  }
}

class FeedAvatar extends StatelessWidget {
  const FeedAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.size = 32,
  });

  final String name;
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(fontSize: size * 0.45),
            )
          : null,
    );
  }
}
