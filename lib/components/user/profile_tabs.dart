import 'package:flutter/material.dart';

import '../layout/edgy.dart';

class ProfileTabs extends StatefulWidget {
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
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs> {
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollTo(widget.active);
    });
  }

  @override
  void didUpdateWidget(ProfileTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollTo(widget.active);
      });
    }
  }

  void _scrollTo(String key) {
    final ctx = _keys[key]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

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
            itemCount: widget.tabs.length,
            itemBuilder: (context, index) {
              final (key, label, count) = widget.tabs[index];
              final selected = key == widget.active;
              final color = selected ? scheme.primary : scheme.onSurfaceVariant;
              return Semantics(
                key: _keys.putIfAbsent(key, GlobalKey.new),
                selected: selected,
                button: true,
                child: InkWell(
                  onTap: () => widget.onSelect(key),
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
