import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../models/review.dart';
import '../feed/feed_markdown.dart';
import '../feed/feed_reactions.dart';
import 'star_rating.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ReviewItem extends StatelessWidget {
  const ReviewItem({
    super.key,
    required this.review,
    required this.currentUserId,
    this.isOwner = false,
    this.onMediaTap,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.reacting = false,
  });

  final UserReview review;
  final String currentUserId;
  final bool isOwner;
  final VoidCallback? onMediaTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(String emoji, FeedReaction? current)? onReact;
  final bool reacting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final config = reviewContent[review.type]!;
    final created = review.createdAt;
    final text = review.summary ?? review.story;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onMediaTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: review.mediaImage.isEmpty
                        ? Container(
                            width: 40,
                            height: 56,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedImage01,
                              size: 18,
                              color: Colors.white38,
                            ),
                          )
                        : Image.network(
                            review.mediaImage,
                            width: 40,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const SizedBox(width: 40, height: 56),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.mediaTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            StarRating(value: review.overall / 2),
                            const SizedBox(width: 6),
                            Text(
                              review.overall.toStringAsFixed(1),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (review.recommended == true)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedThumbsUp,
                      size: 16,
                      color: theme.colorScheme.primary,
                    )
                  else if (review.recommended == false)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedThumbsDown,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
            ),
            if (review.fields.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
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
              const SizedBox(height: 10),
              MarkdownBody(
                data: text,
                styleSheet: feedMarkdownStyleSheet(theme),
              ),
            ],
            if (created != null) ...[
              const SizedBox(height: 8),
              Text(
                DateFormat.yMd(locale).format(created.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
