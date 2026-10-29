import 'package:flutter/material.dart';

class SliverPosterGrid extends StatelessWidget {
  const SliverPosterGrid({super.key, required this.delegate});

  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    final extraTextHeight = MediaQuery.textScalerOf(context).scale(14) - 14;
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.crossAxisExtent + 12) / (132 + extraTextHeight * 2))
                .floor()
                .clamp(1, 8);
        final width =
            (constraints.crossAxisExtent - (columns - 1) * 12) / columns;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: width * 1.5 + 68 + extraTextHeight * 3,
          ),
          delegate: delegate,
        );
      },
    );
  }
}
