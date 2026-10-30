import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../styles/tg_theme.dart';
import '../../../models/person.dart';
import '../media/smooth_image.dart';

class PersonImage extends StatelessWidget {
  const PersonImage({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 144,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: const [BoxShadow(color: TgColors.scrim, blurRadius: 24)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: person.imageUrl != null
              ? SmoothImage(url: person.imageUrl!, error: _imageFallback(theme))
              : _imageFallback(theme),
        ),
      ),
    );
  }

  Widget _imageFallback(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUserRound,
        size: 48,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
