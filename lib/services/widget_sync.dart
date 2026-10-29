import 'package:flutter/services.dart';

abstract final class WidgetSync {
  static const _channel = MethodChannel('trackgeek/widget');

  static Future<void> refresh() async {
    try {
      await _channel.invokeMethod<void>('refresh');
    } catch (_) {}
  }
}
