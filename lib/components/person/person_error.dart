import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/api_exception.dart';

class PersonError extends StatelessWidget {
  const PersonError({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final notFound =
        error is ApiException &&
        (error as ApiException).failure == ApiFailure.notFound;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: HugeIcons.strokeRoundedUserQuestion01, size: 40),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              notFound
                  ? context.t('common:notFound')
                  : context.t('common:internalError'),
              textAlign: TextAlign.center,
            ),
          ),
          if (!notFound) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.t('common:tryAgain')),
            ),
          ],
        ],
      ),
    );
  }
}
