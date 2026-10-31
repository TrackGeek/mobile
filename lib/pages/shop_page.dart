import 'package:flutter/material.dart';

import '../components/layout/content_frame.dart';
import '../styles/tg_layout.dart';

import 'package:hugeicons/hugeicons.dart';

import '../components/shop/shop_item_tile.dart';
import '../components/shop/shop_section.dart';
import '../components/shop/shop_skeleton.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/cosmetic.dart';
import '../models/wallet.dart';
import '../services/shop_service.dart';
import '../styles/tg_theme.dart';
import '../utils/haptics.dart';
import '../utils/numbers.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({
    super.key,
    required this.shop,
    required this.session,
    this.onOpenSettings,
  });

  final ShopService shop;
  final SessionController session;
  final VoidCallback? onOpenSettings;

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  Wallet _wallet = const Wallet(
    balance: 0,
    lifetimeEarned: 0,
    lifetimeSpent: 0,
  );
  CosmeticsBundle _bundle = const CosmeticsBundle(
    profileColors: [],
    avatarFrames: [],
    profileTitles: [],
    bannerEffects: [],
  );
  bool _loading = true;
  bool _failed = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final results = await Future.wait([
        widget.shop.wallet(),
        widget.shop.cosmetics(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _bundle = results[1] as CosmeticsBundle;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        widget.shop.wallet(),
        widget.shop.cosmetics(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Wallet;
        _bundle = results[1] as CosmeticsBundle;
      });
    } catch (_) {}
  }

  String _nameKey(CosmeticKind kind, String key) => switch (kind) {
    CosmeticKind.profileColor => 'cosmetics:gradients.$key',
    CosmeticKind.avatarFrame => 'cosmetics:frames.$key',
    CosmeticKind.profileTitle => 'cosmetics:titles.$key',
    CosmeticKind.bannerEffect => 'cosmetics:bannerEffectNames.$key',
  };

  (dynamic, String) _sectionMeta(CosmeticKind kind) => switch (kind) {
    CosmeticKind.profileColor => (
      HugeIcons.strokeRoundedPalette,
      'cosmetics:gradientColors',
    ),
    CosmeticKind.avatarFrame => (
      HugeIcons.strokeRoundedCircleDashed,
      'cosmetics:avatarFrames',
    ),
    CosmeticKind.profileTitle => (
      HugeIcons.strokeRoundedTag01,
      'cosmetics:profileTitles',
    ),
    CosmeticKind.bannerEffect => (
      HugeIcons.strokeRoundedMagicWand01,
      'cosmetics:bannerEffects',
    ),
  };

  String _errorText(Object error) {
    if (error is ApiException && error.serverCode != null) {
      final key = 'api:${error.serverCode}';
      final value = context.t(key);
      if (value != key) return value;
    }
    return context.t('api:INTERNAL_SERVER_ERROR');
  }

  void _toast(String message, {bool error = false}) {
    error ? HapticsHelper.error() : HapticsHelper.success();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmPurchase(CosmeticKind kind, Cosmetic cosmetic) async {
    final name = context.t(_nameKey(kind, cosmetic.key));
    final result = await showDialog<Object>(
      context: context,
      builder: (dialogContext) {
        var pending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.t('shop:confirmPurchase.title')),
              content: Text(
                context.t('shop:confirmPurchase.description', {
                  'name': name,
                  'price': cosmetic.unlock.price ?? 0,
                }),
              ),
              actions: [
                TextButton(
                  onPressed: pending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(context.t('common:cancel')),
                ),
                FilledButton.icon(
                  onPressed: pending
                      ? null
                      : () async {
                          setDialogState(() => pending = true);
                          setState(() => _purchasing = true);
                          try {
                            await widget.shop.purchaseCosmetic(
                              kind,
                              cosmetic.key,
                            );
                            try {
                              await widget.session.refresh();
                            } catch (_) {}
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          } catch (error) {
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(error);
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _purchasing = false);
                            }
                          }
                        },
                  icon: pending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  label: Text(context.t('shop:confirmPurchase.confirm')),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || result == null) return;
    if (result == true) {
      _toast(context.t('shop:purchase.success', {'name': name}));
      _refresh();
    } else {
      _toast(_errorText(result), error: true);
    }
  }

  void _openSettings() {
    Navigator.of(context).pop();
    widget.onOpenSettings?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('common:shop')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedCoins01,
                      size: 16,
                      color: TgColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.t('common:coinCount', {
                        'count': _wallet.balance,
                        'formattedCount': _wallet.balance.humanizedCount(),
                      }),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ContentFrame(
        maxWidth: TgLayout.contentWidth,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.t('shop:description'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) ...[
              const ShopSkeleton(),
              const SizedBox(height: 16),
              const ShopSkeleton(),
            ] else if (_failed) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        context.t('common:tryAgainLater'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 16,
                        ),
                        label: Text(context.t('common:tryAgain')),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              for (final kind in CosmeticKind.values) ...[
                ShopSection(
                  icon: _sectionMeta(kind).$1,
                  title: context.t(_sectionMeta(kind).$2),
                  hint: context.t('shop:equipHint'),
                  children: [
                    for (final cosmetic in _purchasables(kind))
                      ShopItemTile(
                        kind: kind,
                        cosmetic: cosmetic,
                        name: context.t(_nameKey(kind, cosmetic.key)),
                        affordable:
                            _wallet.balance >= (cosmetic.unlock.price ?? 0),
                        purchasing: _purchasing,
                        onBuy: () => _confirmPurchase(kind, cosmetic),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            if (!_loading && !_failed)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${context.t('shop:goToSettings')} ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onOpenSettings == null ? null : _openSettings,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        context.t('common:settings'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: TgColors.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: TgColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Cosmetic> _purchasables(CosmeticKind kind) => [
    for (final cosmetic in _bundle.itemsFor(kind))
      if (cosmetic.unlock.type == 'purchase') cosmetic,
  ];
}
