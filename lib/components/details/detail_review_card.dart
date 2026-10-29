import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../models/review.dart';
import '../feed/feed_markdown.dart';
import '../feed/feed_reactions.dart';
import '../user/star_rating.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class DetailReviewCard extends StatelessWidget {
  const DetailReviewCard({
    super.key,
    required this.review,
    required this.currentUserId,
    this.isOwner = false,
    this.onUserTap,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.reacting = false,
  });

  final UserReview review;
  final String currentUserId;
  final bool isOwner;
  final VoidCallback? onUserTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String emoji, FeedReaction? current)? onReact;
  final bool reacting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final config = reviewContent[review.type]!;
    final user = review.user;
    final text = review.summary ?? review.story;
    final created = review.createdAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onUserTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                      ? Text(
                          (user?.name.isNotEmpty == true ? user!.name : '?')[0]
                              .toUpperCase(),
                          style: theme.textTheme.labelLarge,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '@${user?.username ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (created != null)
                  Text(
                    DateFormat.yMd(locale).format(created.toLocal()),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            StarRating(value: review.overall),
            const SizedBox(width: 6),
            Text(
              review.overall.toStringAsFixed(1),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (review.recommended == true)
              HugeIcon(
                icon: HugeIcons.strokeRoundedThumbsUp,
                size: 14,
                color: theme.colorScheme.primary,
              )
            else if (review.recommended == false)
              HugeIcon(
                icon: HugeIcons.strokeRoundedThumbsDown,
                size: 14,
                color: theme.colorScheme.error,
              ),
          ],
        ),
        if (review.fields.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final field in config.criteria)
                if (review.fields[field] != null)
                  Text(
                    '${context.t('feed:criteries.${config.criteriaLabels[field]}')} ${review.fields[field]!.toStringAsFixed(1)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
            ],
          ),
        ],
        if (text != null && text.isNotEmpty) ...[
          const SizedBox(height: 8),
          MarkdownBody(data: text, styleSheet: feedMarkdownStyleSheet(theme)),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            FeedReactions(
              currentUserId: currentUserId,
              activityId: review.id,
              reactions: review.reactions,
              onReact: onReact,
              isReacting: reacting,
            ),
            const Spacer(),
            if (isOwner) ...[
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit01,
                  size: 16,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: context.t('feed:edit'),
                onPressed: onEdit,
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: context.t('common:delete'),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
