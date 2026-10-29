import 'package:flutter/material.dart';

import '../../styles/tg_layout.dart';

class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = TgLayout.contentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}
