import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../utils/strings.dart';
import '../media/smooth_image.dart';

class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.onTap,
    this.footer,
  });

  final String name;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = imageUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainerHigh,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: image == null || image.isEmpty
                      ? Container(
                          color: theme.colorScheme.surface,
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedUser,
                              size: 28,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : SmoothImage(
                          url: image,
                          error: Container(
                            color: theme.colorScheme.surface,
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                size: 28,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.orPlaceholder(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isUsable)
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (footer != null) ...[
                const SizedBox(height: 6),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.number,
    required this.title,
    this.imageUrl,
  });

  final String number;
  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl == null || imageUrl!.isEmpty
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          size: 24,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SmoothImage(url: imageUrl!),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title.orPlaceholder(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PeopleGrid extends StatelessWidget {
  const PeopleGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 160,
    this.spacing = 10,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double maxCrossAxisExtent;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / (maxCrossAxisExtent + spacing))
            .ceil()
            .clamp(1, 12);
        final rows = (itemCount / columns).ceil();
        return Column(
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var c = 0; c < columns; c++) ...[
                      if (c > 0) SizedBox(width: spacing),
                      Expanded(
                        child: r * columns + c < itemCount
                            ? itemBuilder(context, r * columns + c)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
