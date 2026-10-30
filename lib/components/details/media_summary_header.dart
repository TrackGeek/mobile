import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/media_detail.dart';
import 'detail_overview.dart';
import '../media/smooth_image.dart';

class MediaSummaryHeader extends StatelessWidget {
  const MediaSummaryHeader({super.key, required this.media});

  final MediaDetail media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: HugeIcon(icon: HugeIcons.strokeRoundedImage01),
      ),
    );
    return DetailOverview(
      cover: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: media.imageUrl == null
              ? fallback
              : SmoothImage(url: media.imageUrl!, error: fallback),
        ),
      ),
      children: [
        const SizedBox(height: 16),
        Text(media.title, style: theme.textTheme.headlineMedium),
        if (media.altTitle != null) ...[
          const SizedBox(height: 8),
          Text(
            media.altTitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (media.score != null && media.score! > 0)
              Chip(
                avatar: const HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 16,
                ),
                label: Text(
                  media.score! > 10
                      ? media.score!.toStringAsFixed(0)
                      : media.score!.toStringAsFixed(1),
                ),
              ),
            if (media.tgScore != null && media.tgScore! > 0)
              Chip(
                avatar: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTrendingUp,
                  size: 16,
                ),
                label: Text('TG ${media.tgScore!.toStringAsFixed(1)}'),
              ),
          ],
        ),
      ],
    );
  }
}
