import 'package:flutter/material.dart';

class DetailOverview extends StatelessWidget {
  const DetailOverview({
    super.key,
    required this.cover,
    required this.children,
  });

  final Widget cover;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final beside =
            constraints.maxWidth >= 560 &&
            MediaQuery.textScalerOf(context).scale(1) < 1.6;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
        if (beside) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 180, child: cover),
              const SizedBox(width: 24),
              Expanded(child: details),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: constraints.maxWidth.clamp(0, 180),
                child: cover,
              ),
            ),
            details,
          ],
        );
      },
    );
  }
}
