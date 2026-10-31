import 'package:flutter/material.dart';

import '../layout/edgy.dart';

class ProfileTabs extends StatelessWidget {
  const ProfileTabs({
    super.key,
    required this.tabs,
    required this.active,
    required this.onSelect,
  });

  final List<(String, String, String?)> tabs;
  final String active;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final animation = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 48 + (MediaQuery.textScalerOf(context).scale(14) - 14),
        child: Edgy(
          axis: .horizontal,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final (key, label, count) = tabs[index];
              final selected = key == active;
              final color = selected ? scheme.primary : scheme.onSurfaceVariant;
              return Semantics(
                selected: selected,
                button: true,
                child: InkWell(
                  onTap: () => onSelect(key),
                  child: AnimatedContainer(
                    duration: animation,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected ? scheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            count,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: selected ? 1 : 0.7,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
