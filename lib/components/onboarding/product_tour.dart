import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../app/tour_keys.dart';
import '../../controllers/tour_controller.dart';
import '../../l10n/l10n_context.dart';

typedef _TourStep = (GlobalKey, String, ContentAlign);

final Map<TourStage, List<_TourStep>> _steps = {
  TourStage.feed: [
    (TourKeys.feedTabs, 'tabs', ContentAlign.bottom),
    (TourKeys.feedCompose, 'compose', ContentAlign.top),
  ],
  TourStage.profile: [
    (TourKeys.profileHeader, 'header', ContentAlign.bottom),
    (TourKeys.profileTabs, 'tabs', ContentAlign.bottom),
  ],
  TourStage.search: [
    (TourKeys.searchBar, 'bar', ContentAlign.top),
    (TourKeys.searchKind, 'kind', ContentAlign.top),
  ],
  TourStage.details: [(TourKeys.statusButtons, 'status', ContentAlign.bottom)],
};

Future<bool> showTourWelcome(BuildContext context) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final start = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.t('app:tour.welcome.title')),
      content: Text(dialogContext.t('app:tour.welcome.description')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(dialogContext.t('app:tour.skip')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(dialogContext.t('app:tour.start')),
        ),
      ],
    ),
  );
  return start ?? false;
}

Future<bool> showTourStage(BuildContext context, TourStage stage) {
  final steps = [
    for (final step in _steps[stage] ?? const <_TourStep>[])
      if (step.$1.currentContext != null) step,
  ];
  if (steps.isEmpty) return Future.value(true);
  final completer = Completer<bool>();
  final last = steps.length - 1;
  final targets = [
    for (final (index, (key, id, align)) in steps.indexed)
      TargetFocus(
        identify: id,
        keyTarget: key,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: align,
            child: _TourCard(
              title: context.t('app:tour.${stage.name}.$id.title'),
              description: context.t('app:tour.${stage.name}.$id.description'),
              hint: index == last
                  ? context.t('app:tour.finish')
                  : context.t('common:next'),
              progress: '${index + 1} / ${steps.length}',
            ),
          ),
        ],
      ),
  ];
  TutorialCoachMark(
    targets: targets,
    textSkip: context.t('app:tour.skip'),
    colorShadow: Colors.black,
    opacityShadow: 0.85,
    paddingFocus: 6,
    onFinish: () {
      if (!completer.isCompleted) completer.complete(true);
    },
    onSkip: () {
      if (!completer.isCompleted) completer.complete(false);
      return true;
    },
  ).show(context: context);
  return completer.future;
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.title,
    required this.description,
    required this.hint,
    required this.progress,
  });

  final String title;
  final String description;
  final String hint;
  final String progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              progress,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white54,
              ),
            ),
            const Spacer(),
            Text(
              hint,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
