import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../utils/profile_cosmetics.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  final String title;
  final List<List<dynamic>>? icon;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class UserEmpty extends StatelessWidget {
  const UserEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.description,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? description;

  const UserEmpty.search({super.key, String? title, this.description})
    : icon = HugeIcons.strokeRoundedSearch01,
      title = title ?? '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: HugeIcon(
                icon: icon,
                size: 28,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UserError extends StatelessWidget {
  const UserError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              context.t('common:somethingWentWrong'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.t('common:tryAgain')),
            ),
          ],
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.frame,
    this.size = 40,
  });

  final String name;
  final String? avatarUrl;
  final String? frame;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final style = frame == null ? null : avatarFrameStyles[frame!];
    final url = avatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: style == null
            ? null
            : Border.all(color: style.color, width: style.width),
        boxShadow: style?.glow ?? const [],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(theme, initial),
              )
            : _fallback(theme, initial),
      ),
    );
  }

  Widget _fallback(ThemeData theme, String initial) => ColoredBox(
    color: theme.colorScheme.primaryContainer,
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    ),
  );
}
