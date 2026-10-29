import 'package:flutter/material.dart';

import '../../models/game_detail.dart';
import '../details/detail_widgets.dart';

class GameFranchiseCard extends StatelessWidget {
  const GameFranchiseCard({super.key, required this.game, required this.onTap});

  final FranchiseGame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverArt(url: game.coverUrl),
          const SizedBox(height: 6),
          Text(
            game.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
