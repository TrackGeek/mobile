import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';

class ProfileError extends StatelessWidget {
  const ProfileError({
    super.key,
    required this.notFound,
    required this.onRetry,
  });

  final bool notFound;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: notFound
                  ? HugeIcons.strokeRoundedUserQuestion01
                  : HugeIcons.strokeRoundedAlert02,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              notFound ? '404' : context.t('user:error'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: notFound ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context
                  .t(notFound ? 'common:notFound' : 'common:internalError')
                  .replaceAll('<br />', '\n'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (notFound)
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 16,
                ),
                label: Text(context.t('common:goHome')),
              )
            else
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.t('common:tryAgain')),
              ),
          ],
        ),
      ),
    );
  }
}
