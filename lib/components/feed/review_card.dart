import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../utils/strings.dart';
import '../user/star_rating.dart';
import 'feed_item_card.dart';
import 'feed_markdown.dart';
import 'feed_reactions.dart';
import 'feed_title.dart';

class ReviewCard extends StatefulWidget {
  const ReviewCard({
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
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;

  Widget _section(ThemeData theme, String label, String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      MarkdownBody(data: text, styleSheet: feedMarkdownStyleSheet(theme)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final entry = widget.entry;
    final review = entry.review;
    final summary = entry.content;
    final hasExtra =
        review != null && (review.story != null || review.notes != null);
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
              onTap: widget.onMediaTap,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: widget.onUserTap,
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
                                entry.profile.name.orPlaceholder(),
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
                    const SizedBox(height: 6),
                    FeedTitle(
                      titleKey: entry.titleKey,
                      values: entry.titleValues,
                      onLinkTap: widget.onTitleLinkTap,
                    ),
                    if (review != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StarRating(value: review.overall),
                          const SizedBox(width: 6),
                          Text(
                            review.overall.toStringAsFixed(1),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (review.recommended != null)
                            HugeIcon(
                              icon: review.recommended!
                                  ? HugeIcons.strokeRoundedThumbsUp
                                  : HugeIcons.strokeRoundedThumbsDown,
                              size: 16,
                              color: review.recommended!
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                        ],
                      ),
                      if (review.criteria.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            for (final criterion in review.criteria)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${context.t('feed:criteries.${criterion.labelKey}')} ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  StarRating(value: criterion.value, size: 11),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                    if (summary.isUsable) ...[
                      const SizedBox(height: 10),
                      _section(theme, context.t('feed:summary'), summary!),
                    ],
                    if (hasExtra) ...[
                      if (_expanded) ...[
                        if (review.story != null) ...[
                          const SizedBox(height: 10),
                          _section(
                            theme,
                            context.t('feed:story'),
                            review.story!,
                          ),
                        ],
                        if (review.notes != null) ...[
                          const SizedBox(height: 10),
                          _section(
                            theme,
                            context.t('feed:notes'),
                            review.notes!,
                          ),
                        ],
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () =>
                              setState(() => _expanded = !_expanded),
                          icon: Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                          ),
                          label: Text(
                            context.t(
                              _expanded ? 'common:showLess' : 'common:showMore',
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
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
                        FeedReactions(
                          currentUserId: widget.currentUserId,
                          activityId: entry.activityId,
                          reactions: entry.reactions,
                          likes: entry.likes,
                          onReact: widget.onReact,
                          isReacting: widget.isReacting,
                          isError: widget.isReactionError,
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
