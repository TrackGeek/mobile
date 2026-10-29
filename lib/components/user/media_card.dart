import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/progress_item.dart';

class MediaCard extends StatelessWidget {
  const MediaCard({
    super.key,
    required this.title,
    required this.image,
    this.year,
    this.item,
    this.onTap,
  });

  final String title;
  final String image;
  final int? year;
  final ProgressItem? item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = item;
    final hasProgress =
        progress != null && progress.current != null && progress.total != null;
    final ratio = hasProgress
        ? (progress.current! / progress.total!).clamp(0.0, 1.0)
        : 0.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _Fallback(),
                    )
                  else
                    const _Fallback(),
                  if (hasProgress)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 4,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${progress.current}/${progress.total}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              if (year != null)
                Expanded(
                  child: Text(
                    '$year',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (progress?.completion != null)
                Text(
                  progress?.completion == '100%'
                      ? '100%'
                      : context.t(
                          'feed:completionStatus.${progress?.completion}',
                        ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              if ((progress?.hoursPlayed ?? 0) > 0)
                Text(
                  '${progress!.hoursPlayed!.toStringAsFixed(0)}h',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => const Center(
    child: HugeIcon(
      icon: HugeIcons.strokeRoundedImage01,
      size: 28,
      color: Colors.white38,
    ),
  );
}
