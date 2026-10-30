import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class PersonActionButton extends StatelessWidget {
  const PersonActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.disabled = false,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: HugeIcon(
                icon: icon,
                size: 18,
                color: color ?? theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
