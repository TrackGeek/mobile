import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/settings_section.dart';
import '../../l10n/l10n_context.dart';

class SettingsNavItem extends StatelessWidget {
  const SettingsNavItem({
    super.key,
    required this.section,
    required this.selected,
    required this.onTap,
    this.trailingIcon,
  });

  final SettingsSection section;
  final bool selected;
  final VoidCallback onTap;
  final dynamic trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.outlineVariant
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: section.icon,
                  size: 16,
                  color: selected
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t(section.labelKey),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailingIcon != null)
                  HugeIcon(
                    icon: trailingIcon,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSectionSelector extends StatelessWidget {
  const SettingsSectionSelector({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionBody extends StatelessWidget {
  const SettingsSectionBody({
    super.key,
    required this.active,
    required this.child,
  });

  final SettingsSection active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.t(active.labelKey), style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          context.t(active.descriptionKey),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}
