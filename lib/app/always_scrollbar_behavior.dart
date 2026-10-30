import 'package:flutter/material.dart';

class AlwaysScrollbarBehavior extends MaterialScrollBehavior {
  const AlwaysScrollbarBehavior();

  @override
  Widget buildScrollbar(context, child, details) {
    return Scrollbar(controller: details.controller, child: child);
  }
}
