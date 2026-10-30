import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_detail.dart';
import '../../utils/strings.dart';

class MediaSummaryFields extends StatelessWidget {
  const MediaSummaryFields({super.key, required this.media});

  final MediaDetail media;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in media.fields)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(field.labelKey),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(field.value.orPlaceholder()),
            ],
          ),
        ),
    ],
  );
}
