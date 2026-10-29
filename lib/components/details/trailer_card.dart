import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../utils/video_links.dart';

class TrailerCard extends StatelessWidget {
  const TrailerCard({super.key, required this.video, required this.onTap});

  final ParsedVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = videoThumbnailUrl(video);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                )
              else
                Container(color: theme.colorScheme.surfaceContainerHighest),
              Container(color: Colors.black.withValues(alpha: 0.35)),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.6),
                    border: Border.all(color: Colors.white70),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
