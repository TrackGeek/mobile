import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackgeek/components/media/zoomable_image.dart';
import 'package:trackgeek/pages/media_gallery_page.dart';
import 'package:trackgeek/models/gallery_item.dart';
import 'package:trackgeek/l10n/l10n_context.dart';

import '../helpers/test_l10n.dart';

void main() {
  final image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    ),
  );

  testWidgets('pinch zoom, pan and reset preserve natural image scale', (
    tester,
  ) async {
    final interactions = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomableImage(
            url: '',
            label: 'Screenshot',
            image: image,
            onInteractionChanged: interactions.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewer);
    final first = await tester.createGesture(pointer: 1);
    final second = await tester.createGesture(pointer: 2);
    await first.down(center - const Offset(50, 0));
    await second.down(center + const Offset(50, 0));
    await tester.pump();
    await first.moveTo(center - const Offset(150, 0));
    await second.moveTo(center + const Offset(150, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    expect(controller.value.getMaxScaleOnAxis(), greaterThan(1));
    expect(interactions.last, isTrue);
    final oldTranslation = controller.value.getTranslation();
    await tester.drag(viewer, const Offset(40, 20));
    await tester.pumpAndSettle();
    expect(controller.value.getTranslation(), isNot(oldTranslation));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(controller.value.getMaxScaleOnAxis(), 1);
    expect(interactions.last, isFalse);
  });
  testWidgets('gallery swipes at natural scale and locks paging during zoom', (
    tester,
  ) async {
    await tester.pumpWidget(
      L10nScope(
        localizations: await testL10n(),
        child: const MaterialApp(
          home: MediaGalleryPage(
            title: 'Gallery',
            items: [
              GalleryItem(url: ''),
              GalleryItem(url: ''),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    final center = tester.getCenter(find.byType(PageView));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<NeverScrollableScrollPhysics>(),
    );
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageView>(find.byType(PageView)).physics,
      isA<PageScrollPhysics>(),
    );
    await tester.drag(find.byType(PageView), const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
  });
}
