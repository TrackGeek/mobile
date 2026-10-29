import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class PersonMetaItem extends StatelessWidget {
  const PersonMetaItem({super.key, required this.icon, required this.text});

  final List<List<dynamic>> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
