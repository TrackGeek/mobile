import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../models/user_profile.dart';
import '../../services/game_service.dart';
import '../../services/user_service.dart';
import 'user_widgets.dart';

class SetupCard extends StatelessWidget {
  const SetupCard({
    super.key,
    required this.user,
    required this.isOwner,
    required this.users,
    required this.games,
    this.onChanged,
  });

  final UserProfile user;
  final bool isOwner;
  final UserService users;
  final GameService games;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = user.profile.setupPhotos;
    final items = user.profile.setupItems;
    final empty = photos.isEmpty && items.isEmpty;
    return UserCard(
      title: context.t('user:setup'),
      trailing: isOwner
          ? IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit01,
                size: 16,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: context.t('user:setupEdit'),
              onPressed: () => _openEdit(context),
            )
          : null,
      child: empty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t('user:noSetup')}\n${context.t('user:noSetupDescription')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _openEdit(context),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 14,
                    ),
                    label: Text(context.t('user:setupAdd')),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photos.isNotEmpty)
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photos[index].url,
                          height: 140,
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 140,
                            width: 200,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (items.isNotEmpty) ...[
                  if (photos.isNotEmpty) const SizedBox(height: 8),
                  for (final item in items) _SetupItemTile(item: item),
                ],
              ],
            ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SetupEditSheet(
        user: user,
        users: users,
        games: games,
        onChanged: onChanged,
      ),
    );
  }
}

class _SetupItemTile extends StatelessWidget {
  const _SetupItemTile({required this.item});

  final SetupItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (item.type == 'DIVIDER') {
      return const Divider(height: 16);
    }
    if (item.type == 'TITLE') {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(
          item.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return InkWell(
      onTap: item.link == null || item.link!.isEmpty
          ? null
          : () => launchUrl(
              Uri.parse(item.link!),
              mode: LaunchMode.externalApplication,
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.brand != null && item.brand!.isNotEmpty)
                    Text(
                      item.brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (item.link != null && item.link!.isNotEmpty)
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUpRight01,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _SetupEditSheet extends StatefulWidget {
  const _SetupEditSheet({
    required this.user,
    required this.users,
    required this.games,
    this.onChanged,
  });

  final UserProfile user;
  final UserService users;
  final GameService games;
  final VoidCallback? onChanged;

  @override
  State<_SetupEditSheet> createState() => _SetupEditSheetState();
}

class _SetupEditSheetState extends State<_SetupEditSheet> {
  late final List<SetupPhoto> _photos = List.of(
    widget.user.profile.setupPhotos,
  );
  late final List<SetupItem> _items = List.of(widget.user.profile.setupItems);
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged?.call();
    } catch (_) {
      // parent refresh restores state
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveItem(int index, int delta) async {
    final next = index + delta;
    if (next < 0 || next >= _items.length) return;
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(next, item);
    });
    await _run(
      () =>
          widget.users.reorderSetupItems([for (final item in _items) item.id]),
    );
  }

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;
    final navigator = Navigator.of(context);
    final bytes = await picked.readAsBytes();
    final filename = picked.name;
    final mime = picked.mimeType;
    await _run(() async {
      final url = await widget.games.uploadImage(
        bytes,
        filename: filename,
        mimeType: mime,
      );
      await widget.users.addSetupPhoto(url);
    });
    if (mounted) navigator.pop();
  }

  Future<void> _editItem([SetupItem? existing, String? forceType]) async {
    final type = forceType ?? existing?.type ?? 'COMPONENT';
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _SetupItemDialog(item: existing, type: type, users: widget.users),
    );
    if (saved == true) {
      widget.onChanged?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                context.t('user:setupEdit'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t('user:setupPhotos'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_photos.isEmpty)
            Text(
              context.t('user:noSetup'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final photo in _photos)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      photo.url,
                      width: 64,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 64,
                        height: 44,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await widget.users.deleteSetupPhoto(photo.id);
                            setState(() => _photos.remove(photo));
                          }),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy ? null : _addPhoto,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 14,
              ),
              label: Text(context.t('user:setupAddPhoto')),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('user:setupComponents'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _items.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _items[i].type == 'DIVIDER'
                        ? Text(
                            '—',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Text(
                            _items[i].name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowUp01,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy || i == 0 ? null : () => _moveItem(i, -1),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy || i == _items.length - 1
                        ? null
                        : () => _moveItem(i, 1),
                  ),
                  if (_items[i].type != 'DIVIDER')
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        size: 14,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: _busy ? null : () => _editItem(_items[i]),
                    ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await widget.users.deleteSetupItem(_items[i].id);
                            setState(() => _items.removeAt(i));
                          }),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _editItem(),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    size: 14,
                  ),
                  label: Text(context.t('user:setupAddItem')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: context.t('user:setupAddTitle'),
                onPressed: _busy ? null : () => _editItem(null, 'TITLE'),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTextFont,
                  size: 16,
                ),
              ),
              IconButton(
                tooltip: context.t('user:setupAddDivider'),
                onPressed: _busy
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        await _run(
                          () => widget.users.createSetupItem(type: 'DIVIDER'),
                        );
                        if (mounted) navigator.pop();
                      },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedMinusSign,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupItemDialog extends StatefulWidget {
  const _SetupItemDialog({this.item, required this.type, required this.users});

  final SetupItem? item;
  final String type;
  final UserService users;

  @override
  State<_SetupItemDialog> createState() => _SetupItemDialogState();
}

class _SetupItemDialogState extends State<_SetupItemDialog> {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _brand = TextEditingController(text: widget.item?.brand);
  late final _link = TextEditingController(text: widget.item?.link);
  bool _saving = false;

  bool get _isTitle => widget.type == 'TITLE';

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (_saving || name.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        await widget.users.createSetupItem(
          type: widget.type,
          name: name,
          brand: _isTitle ? null : _brand.text.trim(),
          link: _isTitle ? null : _link.text.trim(),
        );
      } else {
        await widget.users.updateSetupItem(
          widget.item!.id,
          name: name,
          brand: _isTitle ? null : _brand.text.trim(),
          link: _isTitle ? null : _link.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.t(
        _isTitle
            ? (widget.item == null
                  ? 'user:setupAddTitle'
                  : 'user:setupEditTitle')
            : (widget.item == null
                  ? 'user:setupAddItem'
                  : 'user:setupEditItem'),
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: context.t('common:name'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (!_isTitle) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _brand,
            decoration: InputDecoration(
              labelText: context.t('user:setupBrand'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _link,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: context.t('user:setupLink'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.t('common:cancel')),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(context.t('common:save')),
      ),
    ],
  );
}
