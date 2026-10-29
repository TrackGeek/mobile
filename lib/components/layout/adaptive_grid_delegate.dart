import 'package:flutter/material.dart';

class AdaptiveGridDelegate extends SliverGridDelegateWithMaxCrossAxisExtent {
  AdaptiveGridDelegate({
    required BuildContext context,
    required super.maxCrossAxisExtent,
    double childAspectRatio = 1,
    super.crossAxisSpacing = 12,
    super.mainAxisSpacing = 16,
  }) : super(
         childAspectRatio:
             childAspectRatio /
             (1 + (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 3)),
       );
}
