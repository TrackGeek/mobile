import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/cosmetic.dart';
import '../../styles/tg_theme.dart';
import '../../utils/profile_cosmetics.dart';
import '../../utils/numbers.dart';

class ShopItemTile extends StatelessWidget {
  const ShopItemTile({
    super.key,
    required this.kind,
    required this.cosmetic,
    required this.name,
    required this.affordable,
    required this.purchasing,
    required this.onBuy,
  });

  final CosmeticKind kind;
  final Cosmetic cosmetic;
  final String name;
  final bool affordable;
  final bool purchasing;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final price = cosmetic.unlock.price ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          _Preview(kind: kind, cosmetic: cosmetic),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCoins01,
                      size: 14,
                      color: TgColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      price.humanizedCount(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (cosmetic.owned)
            _StatusBadge(
              label: cosmetic.equipped
                  ? context.t('cosmetics:equipped')
                  : context.t('cosmetics:owned'),
              highlight: cosmetic.equipped,
            )
          else
            OutlinedButton(
              onPressed: affordable && !purchasing ? onBuy : null,
              child: Text(context.t('shop:buy')),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? TgColors.primary.withValues(alpha: 0.2)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: highlight ? TgColors.secondary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.kind, required this.cosmetic});

  final CosmeticKind kind;
  final Cosmetic cosmetic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (kind) {
      CosmeticKind.profileColor => Container(
        width: 40,
        height: 40,
        decoration: profileColorDecoration(
          cosmetic.value,
          radius: 40,
        ).copyWith(border: Border.all(color: scheme.outlineVariant)),
      ),
      CosmeticKind.avatarFrame => Container(
        width: 40,
        height: 40,
        decoration: _frameDecoration(cosmetic.key),
      ),
      CosmeticKind.profileTitle => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Text(
          context.t('cosmetics:titles.${cosmetic.key}'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      CosmeticKind.bannerEffect => Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: TgColors.muted,
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: BannerEffects.painter(cosmetic.key),
          child: DecoratedBox(
            decoration: BannerEffects.decoration(cosmetic.key),
          ),
        ),
      ),
    };
  }

  BoxDecoration _frameDecoration(String key) {
    final style = avatarFrameStyles[key];
    if (style == null) {
      return const BoxDecoration(color: TgColors.muted, shape: BoxShape.circle);
    }
    return BoxDecoration(
      color: TgColors.muted,
      shape: BoxShape.circle,
      border: Border.all(color: style.color, width: style.width),
      boxShadow: style.glow,
    );
  }
}
