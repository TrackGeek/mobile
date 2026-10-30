import 'dart:async';

import 'package:haptic_feedback/haptic_feedback.dart';

class HapticsHelper {
  HapticsHelper._();

  static bool? _canVibrate;

  static Future<void> _vibrate(HapticsType type) async {
    _canVibrate ??= await Haptics.canVibrate();

    if (_canVibrate ?? false) {
      await Haptics.vibrate(type);
    }
  }

  static void success() => unawaited(_vibrate(HapticsType.success));
  static void warning() => unawaited(_vibrate(HapticsType.warning));
  static void error() => unawaited(_vibrate(HapticsType.error));
  static void light() => unawaited(_vibrate(HapticsType.light));
  static void medium() => unawaited(_vibrate(HapticsType.medium));
  static void heavy() => unawaited(_vibrate(HapticsType.heavy));
  static void selection() => unawaited(_vibrate(HapticsType.selection));
}
