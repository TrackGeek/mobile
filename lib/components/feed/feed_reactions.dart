import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';

const quickReactions = ['👍', '❤️', '🔥', '😂', '😮', '😢'];

class FeedReactions extends StatelessWidget {
  const FeedReactions({
    super.key,
    required this.currentUserId,
    this.activityId,
    this.reactions = const [],
    this.likes = 0,
    this.onReact,
    this.isReacting = false,
    this.isError = false,
    this.compact = true,
  });

  final String currentUserId;
  final String? activityId;
  final List<FeedReaction> reactions;
  final int likes;
  final void Function(String emoji, FeedReaction? currentReaction)? onReact;
  final bool isReacting;
  final bool isError;
  final bool compact;

  FeedReaction? get _currentReaction {
    for (final r in reactions) {
      if (r.userId == currentUserId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = L10nScope.of(context).language;
    if (activityId == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 16),
          const SizedBox(width: 6),
          Text(
            '$likes',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final counts = <String, int>{};
    for (final r in reactions) {
      counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
    }
    final current = _currentReaction;
    final popular = counts.keys.toList()
      ..sort((a, b) {
        if (a == current?.emoji) return -1;
        if (b == current?.emoji) return 1;
        return counts[b]!.compareTo(counts[a]!);
      });
    final top = popular.take(3).toList();
    final total = likes > reactions.length ? likes : reactions.length;

    final trigger = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isReacting ? null : () => _openSheet(context, current),
        child: Container(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: current != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            color: current != null
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReacting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (top.isNotEmpty)
                ...top.map(
                  (emoji) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                )
              else
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedSmilePlus,
                  size: 16,
                ),
              if (total > 0) ...[
                const SizedBox(width: 6),
                Text(
                  NumberFormat.compact(locale: locale).format(total),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        trigger,
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertCircle,
                  size: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  context.t('feed:reactionError'),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context, FeedReaction? current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final counts = <String, int>{};
        for (final r in reactions) {
          counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in quickReactions)
                  _EmojiButton(
                    emoji: emoji,
                    count: counts[emoji] ?? 0,
                    active: current?.emoji == emoji,
                    onTap: onReact == null
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            onReact!(emoji, current);
                          },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.count,
    required this.active,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text('$count', style: theme.textTheme.labelMedium),
            ],
            if (active) ...[
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheck,
                size: 12,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
