import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';

class SearchError extends StatelessWidget {
  const SearchError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
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
