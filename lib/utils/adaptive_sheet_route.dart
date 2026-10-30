import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

import '../styles/tg_theme.dart';

extension WidgetX on Widget {
  Route<T> asAdaptiveSheetRoute<T>() {
    final surface = Material(color: TgColors.card, child: this);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return StupidSimpleCupertinoSheetRoute<T>(child: surface);
    }
    return StupidSimpleSheetRoute<T>(
      child: SafeArea(bottom: false, left: false, right: false, child: surface),
    );
  }
}
