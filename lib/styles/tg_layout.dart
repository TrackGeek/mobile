import 'package:flutter/material.dart';

abstract final class TgLayout {
  static const contentWidth = 1200.0;
  static const readingWidth = 760.0;
  static const formWidth = 560.0;
  static const railBreakpoint = 720.0;
  static const expandedBreakpoint = 1100.0;

  static EdgeInsets pagePadding(double width) => EdgeInsets.symmetric(
    horizontal: width < 600 ? 16 : (width < expandedBreakpoint ? 24 : 32),
  );
}
