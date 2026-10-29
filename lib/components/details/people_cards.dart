import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

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
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
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
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
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
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
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
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
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
                    title,
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
