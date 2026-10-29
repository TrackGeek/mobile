import 'package:flutter/widgets.dart';

import 'trackgeek_localizations.dart';

class L10nScope extends InheritedNotifier<TrackGeekLocalizations> {
  const L10nScope({
    super.key,
    required TrackGeekLocalizations localizations,
    required super.child,
  }) : super(notifier: localizations);

  static TrackGeekLocalizations of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    assert(scope != null, 'L10nScope missing');
    return scope!.notifier!;
  }
}

extension TrackGeekL10n on BuildContext {
  String t(String key, [Map<String, Object?> params = const {}]) =>
      L10nScope.of(this).t(key, params);
}
