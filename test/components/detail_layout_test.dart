import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:trackgeek/components/details/community_stats.dart';
import 'package:trackgeek/components/details/detail_overview.dart';
import 'package:trackgeek/components/details/people_cards.dart';
import 'package:trackgeek/components/details/tracking.dart';
import 'package:trackgeek/components/layout/adaptive_grid_delegate.dart';
import 'package:trackgeek/components/layout/content_frame.dart';
import 'package:trackgeek/styles/tg_theme.dart';

void main() {
  for (final width in [320.0, 760.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Detail sections fit width $width and text scale $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            theme: trackGeekTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: ContentFrame(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DetailOverview(
                          cover: const AspectRatio(
                            aspectRatio: 2 / 3,
                            child: ColoredBox(color: Colors.grey),
                          ),
                          children: [
                            QuickStatusButtons(
                              buttons: [
                                for (final label in [
                                  'Planeado',
                                  'A acompanhar',
                                  'Concluído',
                                ])
                                  StatusButtonConfig(
                                    label: label,
                                    icon: HugeIcons.strokeRoundedBookmark01,
                                    color: Colors.green,
                                    isActive: false,
                                    onTap: () {},
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CommunityStats(
                              stats: [
                                for (var i = 0; i < 5; i++)
                                  CommunityStatItem(
                                    label: 'A acompanhar novamente',
                                    icon: HugeIcons.strokeRoundedBookmark01,
                                    color: Colors.green,
                                    percentage: '35%',
                                    count: '123 pessoas',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: AdaptiveGridDelegate(
                              context: context,
                              maxCrossAxisExtent: 180,
                              childAspectRatio: 0.5,
                            ),
                            itemCount: 8,
                            itemBuilder: (_, index) => PersonTile(
                              name: 'Nome completo de pessoa $index',
                              subtitle: 'Personagem com nome comprido',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        final frameSize = tester.getSize(find.byType(ContentFrame));
        expect(frameSize.width, lessThanOrEqualTo(1280));
      });
    }
  }

  testWidgets(
    'Responsive status actions preserve disabled state and callbacks',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              child: QuickStatusButtons(
                buttons: [
                  StatusButtonConfig(
                    label: 'Active action',
                    icon: HugeIcons.strokeRoundedBookmark01,
                    color: Colors.green,
                    isActive: true,
                    onTap: () => taps++,
                  ),
                  StatusButtonConfig(
                    label: 'Disabled action',
                    icon: HugeIcons.strokeRoundedBookmark01,
                    color: Colors.green,
                    isActive: false,
                    disabled: true,
                    onTap: () => taps++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Active action'));
      await tester.tap(find.text('Disabled action'));
      expect(taps, 1);
    },
  );
}
