import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../styles/tg_theme.dart';
import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/cosmetic.dart';
import '../../services/settings_service.dart';
import '../../utils/profile_cosmetics.dart';
import 'settings_card.dart';
import '../media/smooth_image.dart';

const _defaultColor = '#10b981';

const _uploadMime = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
};

class AppearanceSection extends StatefulWidget {
  const AppearanceSection({
    super.key,
    required this.session,
    required this.settings,
  });

  final SessionController session;
  final SettingsService settings;

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  final _picker = ImagePicker();
  Future<CosmeticsBundle>? _cosmetics;
  String? _color;
  String? _lastSavedColor;
  bool _pendingUpload = false;
  bool _pendingCosmetic = false;

  @override
  void initState() {
    super.initState();
    _syncColor();
    widget.session.addListener(_syncColor);
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncColor);
    super.dispose();
  }

  void _syncColor() {
    final server = widget.session.user?.color ?? _defaultColor;
    _cosmetics = widget.settings.cosmetics();
    if (_lastSavedColor != server || _color == null) {
      _lastSavedColor = server;
      _color = server;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveColor(String value) async {
    if (value == _lastSavedColor) return;
    _lastSavedColor = value;
    try {
      await widget.settings.updateProfile({'color': value});
      await widget.session.refresh();
      if (mounted) {
        showSettingsToast(context, context.t('settings:save.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:save.error'),
          error: true,
        );
      }
    }
  }

  Future<void> _equip(String field, String key) async {
    setState(() => _pendingCosmetic = true);
    try {
      await widget.settings.updateProfile({field: key == 'none' ? null : key});
      setState(() {
        _cosmetics = widget.settings.cosmetics();
      });
      await widget.session.refresh();
      if (mounted) {
        showSettingsToast(context, context.t('settings:save.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:save.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingCosmetic = false);
    }
  }

  String? _unlockRequirement(BuildContext context, Cosmetic cosmetic) {
    final unlock = cosmetic.unlock;
    return switch (unlock.type) {
      'level' => context.t('cosmetics:requirements.level', {
        'level': unlock.value,
      }),
      'mission' => context.t('cosmetics:requirements.mission', {
        'mission': context.t('missions:names.${unlock.key}'),
      }),
      'purchase' => context.t('cosmetics:requirements.purchase', {
        'price': unlock.price,
      }),
      _ => null,
    };
  }

  Future<void> _pickAndUpload(String kind) async {
    if (_pendingUpload) return;
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final ext = file.name.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingUpload = true);
    final isAvatar = kind == 'avatar';
    try {
      if (isAvatar) {
        await widget.settings.uploadAvatar(bytes, file.name, _uploadMime[ext]);
      } else {
        await widget.settings.uploadBanner(bytes, file.name, _uploadMime[ext]);
      }
      await widget.session.refresh();
      if (mounted) {
        showSettingsToast(context, context.t('settings:$kind.upload.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:$kind.upload.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingUpload = false);
    }
  }

  Future<void> _deleteImage(String kind) async {
    if (_pendingUpload) return;
    setState(() => _pendingUpload = true);
    try {
      if (kind == 'avatar') {
        await widget.settings.deleteAvatar();
      } else {
        await widget.settings.deleteBanner();
      }
      await widget.session.refresh();
      if (mounted) {
        showSettingsToast(context, context.t('settings:$kind.delete.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:$kind.delete.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pendingUpload = false);
    }
  }

  Future<void> _pickCustomColor() async {
    final controller = TextEditingController(
      text: (_color ?? _defaultColor).startsWith('#') ? _color! : _defaultColor,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Color? preview;
            final text = controller.text.trim();
            final normalized = text.startsWith('#') ? text : '#$text';
            preview = parseHexColor(normalized);
            return AlertDialog(
              title: Text(context.t('cosmetics:customColor')),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '#10B981',
                  errorText: error,
                  prefixIcon: preview == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: preview,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                onChanged: (_) => setDialogState(() => error = null),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.t('common:cancel')),
                ),
                FilledButton(
                  onPressed: preview == null
                      ? () => setDialogState(
                          () => error = context.t(
                            'settings:color.errors.invalid',
                          ),
                        )
                      : () => Navigator.of(dialogContext).pop(normalized),
                  child: Text(context.t('common:save')),
                ),
              ],
            );
          },
        );
      },
    );
    if (picked == null) return;
    setState(() => _color = picked);
    await _saveColor(picked);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    final color = _color ?? _defaultColor;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsCard(
              icon: HugeIcons.strokeRoundedImage01,
              title: context.t('settings:avatar.title'),
              description: context.t('settings:avatar.description'),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _UploadableImage(
                        imageUrl: user?.avatarUrl,
                        pending: _pendingUpload,
                        fallback: profileColorDecoration(color),
                        uploadLabel: context.t('settings:avatar.upload.title'),
                        deleteLabel: context.t('common:delete'),
                        hasImage: user?.avatarUrl != null,
                        onUpload: () => _pickAndUpload('avatar'),
                        onDelete: user?.avatarUrl != null
                            ? () => _deleteImage('avatar')
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsCard(
              icon: HugeIcons.strokeRoundedImage01,
              title: context.t('settings:banner.title'),
              description: context.t('settings:banner.description'),
              children: [
                AspectRatio(
                  aspectRatio: 2,
                  child: _UploadableImage(
                    imageUrl: user?.bannerUrl,
                    pending: _pendingUpload,
                    fallback: profileColorDecoration(color),
                    uploadLabel: context.t('settings:banner.upload.title'),
                    deleteLabel: context.t('common:delete'),
                    hasImage: user?.bannerUrl != null,
                    onUpload: () => _pickAndUpload('banner'),
                    onDelete: user?.bannerUrl != null
                        ? () => _deleteImage('banner')
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<CosmeticsBundle>(
              future: _cosmetics,
              builder: (context, snapshot) {
                final data = snapshot.data;
                final solids =
                    data?.profileColors
                        .where((c) => !isGradientColor(c.value))
                        .toList() ??
                    [];
                final gradients =
                    data?.profileColors
                        .where((c) => isGradientColor(c.value))
                        .toList() ??
                    [];
                final isCustom =
                    color.startsWith('#') &&
                    !solids.any((c) => c.value == color);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsCard(
                      icon: HugeIcons.strokeRoundedPalette,
                      title: context.t('settings:color.title'),
                      description: context.t('settings:color.description'),
                      children: [
                        SettingsFieldLabel(context.t('settings:color.options')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final cosmetic in solids)
                              _ColorSwatch(
                                color: parseHexColor(cosmetic.value),
                                selected: color == cosmetic.value,
                                locked: false,
                                tooltip: context.t(
                                  'cosmetics:colors.${cosmetic.key}',
                                ),
                                onTap: () {
                                  setState(() => _color = cosmetic.value);
                                  _saveColor(cosmetic.value);
                                },
                              ),
                            _ColorSwatch(
                              color: isCustom ? parseHexColor(color) : null,
                              selected: isCustom,
                              locked: false,
                              tooltip: context.t('cosmetics:customColor'),
                              custom: true,
                              onTap: _pickCustomColor,
                            ),
                          ],
                        ),
                        if (gradients.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SettingsFieldLabel(
                            context.t('cosmetics:gradientColors'),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final cosmetic in gradients)
                                _ColorSwatch(
                                  decoration: profileColorDecoration(
                                    cosmetic.value,
                                    radius: 40,
                                  ),
                                  selected: color == cosmetic.value,
                                  locked: !cosmetic.unlocked,
                                  tooltip: context.t(
                                    'cosmetics:gradients.${cosmetic.key}',
                                  ),
                                  requirement: cosmetic.unlocked
                                      ? null
                                      : _unlockRequirement(context, cosmetic),
                                  onTap: cosmetic.unlocked
                                      ? () {
                                          setState(
                                            () => _color = cosmetic.value,
                                          );
                                          _saveColor(cosmetic.value);
                                        }
                                      : null,
                                ),
                            ],
                          ),
                        ],
                        if (color != _defaultColor) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pendingCosmetic
                                ? null
                                : () {
                                    setState(() => _color = _defaultColor);
                                    _saveColor(_defaultColor);
                                  },
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedRotateLeft01,
                              size: 16,
                            ),
                            label: Text(context.t('settings:color.reset')),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsCard(
                      icon: HugeIcons.strokeRoundedSparkles,
                      title: context.t('cosmetics:equip.title'),
                      description: context.t('cosmetics:equip.description'),
                      children: [
                        SettingsFieldLabel(context.t('cosmetics:avatarFrames')),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final cosmetic
                                in data?.avatarFrames ?? const <Cosmetic>[])
                              _CosmeticBubble(
                                size: 48,
                                equipped: cosmetic.equipped,
                                locked: !cosmetic.unlocked,
                                tooltip: context.t(
                                  'cosmetics:frames.${cosmetic.key}',
                                ),
                                requirement: cosmetic.unlocked
                                    ? null
                                    : _unlockRequirement(context, cosmetic),
                                decoration: _frameDecoration(cosmetic.key),
                                onTap: cosmetic.unlocked && !_pendingCosmetic
                                    ? () => _equip('avatarFrame', cosmetic.key)
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SettingsFieldLabel(
                          context.t('cosmetics:profileTitles'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final cosmetic
                                in data?.profileTitles ?? const <Cosmetic>[])
                              _TitlePill(
                                label: context.t(
                                  'cosmetics:titles.${cosmetic.key}',
                                ),
                                equipped: cosmetic.equipped,
                                locked: !cosmetic.unlocked,
                                requirement: cosmetic.unlocked
                                    ? null
                                    : _unlockRequirement(context, cosmetic),
                                onTap: cosmetic.unlocked && !_pendingCosmetic
                                    ? () => _equip('title', cosmetic.key)
                                    : null,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SettingsFieldLabel(
                          context.t('cosmetics:bannerEffects'),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final cosmetic
                                in data?.bannerEffects ?? const <Cosmetic>[])
                              _BannerEffectSwatch(
                                effectKey: cosmetic.key,
                                equipped: cosmetic.equipped,
                                locked: !cosmetic.unlocked,
                                tooltip: context.t(
                                  'cosmetics:bannerEffectNames.${cosmetic.key}',
                                ),
                                requirement: cosmetic.unlocked
                                    ? null
                                    : _unlockRequirement(context, cosmetic),
                                onTap: cosmetic.unlocked && !_pendingCosmetic
                                    ? () => _equip('bannerEffect', cosmetic.key)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  BoxDecoration _frameDecoration(String key) {
    final style = avatarFrameStyles[key];
    if (style == null) {
      return const BoxDecoration(
        color: TgColors.raised,
        shape: BoxShape.circle,
      );
    }
    return BoxDecoration(
      color: TgColors.raised,
      shape: BoxShape.circle,
      border: Border.all(color: style.color, width: style.width),
      boxShadow: style.glow,
    );
  }
}

class _UploadableImage extends StatelessWidget {
  const _UploadableImage({
    required this.imageUrl,
    required this.pending,
    required this.fallback,
    required this.uploadLabel,
    required this.deleteLabel,
    required this.hasImage,
    required this.onUpload,
    this.onDelete,
  });

  final String? imageUrl;
  final bool pending;
  final Decoration fallback;
  final String uploadLabel;
  final String deleteLabel;
  final bool hasImage;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage && imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SmoothImage(
              url: imageUrl!,
              error: Container(decoration: fallback),
            ),
          )
        else
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: fallback,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: pending ? null : onUpload,
                child: Center(
                  child: pending
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedUpload01,
                              size: 32,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              uploadLabel,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        if (hasImage && pending)
          Container(
            decoration: BoxDecoration(
              color: TgColors.scrim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        if (hasImage && !pending) ...[
          Positioned(
            top: 8,
            right: 40,
            child: _ImageAction(
              icon: HugeIcons.strokeRoundedUpload01,
              label: uploadLabel,
              onTap: onUpload,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _ImageAction(
              icon: HugeIcons.strokeRoundedCancelCircle,
              label: deleteLabel,
              onTap: onDelete,
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageAction extends StatelessWidget {
  const _ImageAction({required this.icon, required this.label, this.onTap});

  final dynamic icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TgColors.scrim,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: HugeIcon(icon: icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    this.color,
    this.decoration,
    required this.selected,
    required this.locked,
    required this.tooltip,
    this.requirement,
    this.custom = false,
    this.onTap,
  });

  final Color? color;
  final BoxDecoration? decoration;
  final bool selected;
  final bool locked;
  final String tooltip;
  final String? requirement;
  final bool custom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final swatch = Container(
      width: 40,
      height: 40,
      decoration:
          (decoration ?? BoxDecoration(color: color, shape: BoxShape.circle))
              .copyWith(
                border: Border.all(
                  color: selected ? scheme.tertiary : Colors.transparent,
                  width: 2,
                ),
              ),
      child: locked
          ? const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLock,
                size: 16,
                color: Colors.white,
              ),
            )
          : custom
          ? const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPipette,
                size: 16,
                color: Colors.white,
              ),
            )
          : null,
    );
    return Tooltip(
      message: requirement == null ? tooltip : '$tooltip\n$requirement',
      child: InkWell(
        onTap: locked ? null : onTap,
        customBorder: const CircleBorder(),
        child: Opacity(opacity: locked ? 0.4 : 1, child: swatch),
      ),
    );
  }
}

class _CosmeticBubble extends StatelessWidget {
  const _CosmeticBubble({
    required this.size,
    required this.equipped,
    required this.locked,
    required this.tooltip,
    this.requirement,
    required this.decoration,
    this.onTap,
  });

  final double size;
  final bool equipped;
  final bool locked;
  final String tooltip;
  final String? requirement;
  final BoxDecoration decoration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: requirement == null ? tooltip : '$tooltip\n$requirement',
      child: InkWell(
        onTap: locked ? null : onTap,
        customBorder: const CircleBorder(),
        child: Opacity(
          opacity: locked ? 0.4 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: decoration.copyWith(
              border: equipped
                  ? Border.all(color: scheme.tertiary, width: 2)
                  : null,
            ),
            child: locked
                ? const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLock,
                      size: 16,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({
    required this.label,
    required this.equipped,
    required this.locked,
    this.requirement,
    this.onTap,
  });

  final String label;
  final bool equipped;
  final bool locked;
  final String? requirement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: requirement ?? label,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: locked ? 0.4 : 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: equipped ? scheme.tertiary : scheme.outlineVariant,
                width: equipped ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (locked)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLock,
                      size: 12,
                    ),
                  ),
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerEffectSwatch extends StatelessWidget {
  const _BannerEffectSwatch({
    required this.effectKey,
    required this.equipped,
    required this.locked,
    required this.tooltip,
    this.requirement,
    this.onTap,
  });

  final String effectKey;
  final bool equipped;
  final bool locked;
  final String tooltip;
  final String? requirement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final painter = BannerEffects.painter(effectKey);
    return Tooltip(
      message: requirement == null ? tooltip : '$tooltip\n$requirement',
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          opacity: locked ? 0.4 : 1,
          child: Container(
            width: 80,
            height: 48,
            decoration: BoxDecoration(
              color: TgColors.raised,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: equipped ? scheme.tertiary : Colors.transparent,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: painter,
              child: DecoratedBox(
                decoration: BannerEffects.decoration(effectKey),
                child: locked
                    ? const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedLock,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
