import 'package:flutter/material.dart';

const _chartColors = [
  Color(0xFF4661E6),
  Color(0xFF10B981),
  Color(0xFFE3A008),
  Color(0xFF9C4EDD),
  Color(0xFFE5484D),
];

class GenrePills extends StatelessWidget {
  const GenrePills({
    super.key,
    required this.genres,
    this.labelOf,
    this.onOpen,
  });

  final List<String> genres;
  final String Function(String genre)? labelOf;
  final void Function(String genre)? onOpen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < genres.length; i++)
          _Pill(
            label: labelOf?.call(genres[i]) ?? genres[i],
            color: _chartColors[i % _chartColors.length],
            onTap: onOpen == null ? null : () => onOpen!(genres[i]),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
