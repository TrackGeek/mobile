import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class FranchiseBannerPlaceholder extends StatelessWidget {
  const FranchiseBannerPlaceholder({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
