import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          _Star(
            fill: (value - i).clamp(0.0, 1.0),
            size: size,
            color: theme.colorScheme.primary,
            emptyColor: theme.colorScheme.outlineVariant,
          ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.fill,
    required this.size,
    required this.color,
    required this.emptyColor,
  });

  final double fill;
  final double size;
  final Color color;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Icon(Icons.star_rounded, size: size, color: emptyColor),
      ClipRect(
        clipper: _FillClipper(fill),
        child: Icon(Icons.star_rounded, size: size, color: color),
      ),
    ],
  );
}

class _FillClipper extends CustomClipper<Rect> {
  const _FillClipper(this.fill);

  final double fill;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_FillClipper old) => old.fill != fill;
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double size;

  void _handleTap(double maxWidth, Offset position) {
    final star = (position.dx / (maxWidth / 5)).floor().clamp(0, 4);
    final frac = position.dx - star * (maxWidth / 5);
    final isHalf = frac < maxWidth / 10;
    final next = star + (isHalf ? 0.5 : 1.0);
    onChanged(next == value ? 0 : next.clamp(0.5, 5.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = size * 5 + 32;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handleTap(width, d.localPosition),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 5; i++) ...[
                _Star(
                  fill: (value - i).clamp(0.0, 1.0),
                  size: size,
                  color: theme.colorScheme.primary,
                  emptyColor: theme.colorScheme.outlineVariant,
                ),
                if (i < 4) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}
