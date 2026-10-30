import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/tg_layout.dart';

class AdaptiveNavigation extends StatefulWidget {
  const AdaptiveNavigation({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final Widget body;
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<AdaptiveNavigation> createState() => _AdaptiveNavigationState();
}

class _AdaptiveNavigationState extends State<AdaptiveNavigation>
    with SingleTickerProviderStateMixin {
  static const _tabKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant AdaptiveNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rail = constraints.maxWidth >= TgLayout.railBreakpoint;
      final extended = constraints.maxWidth >= 1400;
      return CallbackShortcuts(
        bindings: {
          for (var i = 0; i < widget.destinations.length && i < 9; i++)
            SingleActivator(_tabKeys[i], alt: true): () => widget.onSelected(i),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                Offstage(
                  offstage: !rail,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                constraints.maxHeight -
                                MediaQuery.paddingOf(context).vertical,
                          ),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              extended: extended,
                              minExtendedWidth: 224,
                              selectedIndex: widget.selectedIndex,
                              onDestinationSelected: widget.onSelected,
                              labelType: extended
                                  ? NavigationRailLabelType.none
                                  : NavigationRailLabelType.all,
                              leading: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: extended
                                    ? Text(
                                        'TrackGeek',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      )
                                    : Image.asset(
                                        'assets/images/logo.png',
                                        width: 36,
                                        height: 36,
                                        errorBuilder: (_, _, _) => Text(
                                          'TG',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                              ),
                              destinations: [
                                for (final destination in widget.destinations)
                                  NavigationRailDestination(
                                    icon: destination.icon,
                                    selectedIcon: destination.selectedIcon,
                                    label: Text(destination.label),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(opacity: _fade, child: widget.body),
                ),
              ],
            ),
            bottomNavigationBar: rail
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: widget.selectedIndex,
                      onDestinationSelected: widget.onSelected,
                      destinations: widget.destinations,
                    ),
                  ),
          ),
        ),
      );
    },
  );
}
