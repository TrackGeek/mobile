import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../styles/tg_theme.dart';
import '../../../l10n/l10n_context.dart';
import '../../models/progress_item.dart';
import '../media/smooth_image.dart';
import '../../utils/numbers.dart';

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
                    SmoothImage(url: image, error: const _Fallback())
                  else
                    const _Fallback(),
                  if (hasProgress)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: TgColors.scrim,
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
                              '${progress.current!.humanizedCount()}/${progress.total!.humanizedCount()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (progress != null &&
                      (progress.completion != null ||
                          (progress.hoursPlayed ?? 0) > 0))
                    Positioned(
                      left: 4,
                      right: 4,
                      bottom: hasProgress ? 46 : 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (progress.completion != null)
                            Tooltip(
                              message: progress.completion == '100%'
                                  ? '100%'
                                  : context.t(
                                      'feed:completionStatus.${progress.completion}',
                                    ),
                              child: _Badge(
                                padding: const EdgeInsets.all(4),
                                child: _CompletionIcon(progress.completion!),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          if ((progress.hoursPlayed ?? 0) > 0)
                            _Badge(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${progress.hoursPlayed!.humanizedCount(decimalDigits: 0)}h',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        padding: padding,
        child: child,
      ),
    ),
  );
}

class _CompletionIcon extends StatelessWidget {
  const _CompletionIcon(this.completion);

  final String completion;

  @override
  Widget build(BuildContext context) {
    if (completion == 'endless') {
      return const Icon(Icons.all_inclusive, size: 12, color: Colors.white);
    }
    final fraction = switch (completion) {
      'mainStory' => 0.25,
      'mainStoryPlusExtras' => 0.5,
      _ => 1.0,
    };
    return CustomPaint(
      size: const Size.square(12),
      painter: _PiePainter(fraction),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter(this.fraction);

  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()..color = Colors.white;
    canvas.drawCircle(rect.center, size.width / 2 - 0.6, ring);
    canvas.drawArc(
      rect.deflate(1.8),
      -math.pi / 2,
      2 * math.pi * fraction,
      true,
      fill,
    );
  }

  @override
  bool shouldRepaint(_PiePainter old) => old.fraction != fraction;
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => Center(
    child: HugeIcon(
      icon: HugeIcons.strokeRoundedImage01,
      size: 28,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
