import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';

class FeedTabs extends StatelessWidget {
  const FeedTabs({super.key, required this.active, required this.onChanged});

  final FeedKind active;
  final ValueChanged<FeedKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = [
      (
        FeedKind.following,
        context.t('common:following'),
        HugeIcons.strokeRoundedUsers,
      ),
      (FeedKind.global, context.t('feed:global'), HugeIcons.strokeRoundedGlobe),
      (
        FeedKind.trending,
        context.t('feed:trending'),
        HugeIcons.strokeRoundedFlame,
      ),
    ];
    return Container(
      height: 48 + (MediaQuery.textScalerOf(context).scale(14) - 14),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final (kind, label, icon) in tabs)
            Expanded(
              child: Semantics(
                selected: active == kind,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(kind),
                  child: AnimatedContainer(
                    height: double.infinity,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: active == kind
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: icon,
                          size: 16,
                          color: active == kind
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: active == kind
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: active == kind
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
