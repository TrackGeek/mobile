import 'package:flutter/material.dart';

class ShopSkeleton extends StatelessWidget {
  const ShopSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
