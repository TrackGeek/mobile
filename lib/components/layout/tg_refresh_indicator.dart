import 'package:flutter/material.dart';

import '../../utils/haptics.dart';

class TgRefreshIndicator extends StatelessWidget {
  const TgRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticsHelper.medium();
        await onRefresh();
      },
      child: child,
    );
  }
}
