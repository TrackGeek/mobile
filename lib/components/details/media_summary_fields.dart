import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_detail.dart';
import '../../utils/dates.dart';
import '../../utils/strings.dart';
import '../../utils/numbers.dart';

class MediaSummaryFields extends StatelessWidget {
  const MediaSummaryFields({super.key, required this.media});

  final MediaDetail media;

  static const _dateLabelKeys = {
    'common:releaseDate',
    'common:firstAirDate',
    'common:lastAirDate',
  };

  @override
  Widget build(BuildContext context) {
    final language = L10nScope.of(context).language;
    return Column(
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
                Text(
                  (_dateLabelKeys.contains(field.labelKey)
                          ? formatLongDate(field.value, language)
                          : null) ??
                      (int.tryParse(field.value)?.humanizedCount() ??
                          field.value.orPlaceholder()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
