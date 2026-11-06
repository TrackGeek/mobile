import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../models/progress_item.dart';
import '../../utils/numbers.dart';

class GameProgressBadges extends StatelessWidget {
  const GameProgressBadges({super.key, required this.item});

  final ProgressItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (item.completion != null)
          Tooltip(
            message: item.completion == '100%'
                ? '100%'
                : context.t('feed:completionStatus.${item.completion}'),
            child: _Badge(
              padding: const EdgeInsets.all(4),
              child: _CompletionIcon(item.completion!),
            ),
          )
        else
          const SizedBox.shrink(),
        if ((item.hoursPlayed ?? 0) > 0)
          _Badge(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 10, color: Colors.white),
                const SizedBox(width: 2),
                Text(
                  '${item.hoursPlayed!.humanizedCount(decimalDigits: 0)}h',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
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
