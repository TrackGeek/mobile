import 'package:flutter/material.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
  });

  final List<(String, String)> tabs;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48 + (MediaQuery.textScalerOf(context).scale(14) - 14),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (key, label) = tabs[index];
          final selected = key == active;
          return Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              onTap: () => onSelect(key),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
