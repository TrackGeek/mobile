import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ShopSection extends StatelessWidget {
  const ShopSection({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.children,
  });

  final dynamic icon;
  final String title;
  final String hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(icon: icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 780 ? 2 : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final child in children)
                      SizedBox(width: width, child: child),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
