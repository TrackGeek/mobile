import 'package:flutter/material.dart';

class SliverPosterGrid extends StatelessWidget {
  const SliverPosterGrid({
    super.key,
    required this.delegate,
    this.textHeight = 56,
  });

  final SliverChildDelegate delegate;
  final double textHeight;

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
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: width * 1.5 + textHeight + extraTextHeight * 3,
          ),
          delegate: delegate,
        );
      },
    );
  }
}
