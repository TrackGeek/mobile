import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:trackgeek/components/layout/adaptive_navigation.dart';
import 'package:trackgeek/components/layout/content_frame.dart';
import 'package:trackgeek/styles/tg_theme.dart';

const _labels = ['Home', 'Search', 'Notifications', 'Profile', 'Settings'];

Widget _app({double textScale = 1, bool reducedMotion = false}) => MaterialApp(
  theme: trackGeekTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: reducedMotion,
    ),
    child: child!,
  ),
  home: const _NavigationHarness(),
);

class _NavigationHarness extends StatefulWidget {
  const _NavigationHarness();

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) => AdaptiveNavigation(
    selectedIndex: _selected,
    onSelected: (value) => setState(() => _selected = value),
    destinations: [
      for (final label in _labels)
        NavigationDestination(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedHome01),
          label: label,
        ),
    ],
    body: IndexedStack(
      index: _selected,
      children: [
        const ContentFrame(
          child: Scaffold(body: TextField(key: ValueKey('draft'))),
        ),
        for (final label in _labels.skip(1)) Center(child: Text('$label page')),
      ],
    ),
  );
}

void main() {
  testWidgets('resize retains drafts across bottom navigation and rail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('draft')), 'Keep draft');
    tester.view.physicalSize = const Size(1024, 768);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Keep draft'), findsOneWidget);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    expect(find.text('Search page'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpAndSettle();
    expect(find.text('Keep draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact navigation fits enlarged text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('short wide window scrolls rail at 200 percent text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 360);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(textScale: 2, reducedMotion: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(find.text('Notifications page'), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(IndexedStack),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
  });
}
