import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/watch_link.dart';
import '../../services/settings_service.dart';
import '../../utils/watch_links.dart';
import 'settings_card.dart';
import '../../utils/haptics.dart';

const _labelMaxLength = 40;

const _typeIcons = {
  MediaType.movie: HugeIcons.strokeRoundedClapperboard,
  MediaType.tv: HugeIcons.strokeRoundedTvMinimalPlay,
  MediaType.anime: HugeIcons.strokeRoundedMountain,
};

const _typeLabels = {
  MediaType.movie: 'common:types.movie_other',
  MediaType.tv: 'common:types.tv_other',
  MediaType.anime: 'common:types.anime_other',
};

class WatchLinksCard extends StatefulWidget {
  const WatchLinksCard({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<WatchLinksCard> createState() => _WatchLinksCardState();
}

class _WatchLinksCardState extends State<WatchLinksCard> {
  List<WatchLink>? _links;
  String? _editingId;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final links = await widget.settings.watchLinks();
      if (mounted) setState(() => _links = links);
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'common:somethingWentWrong'),
          error: true,
        );
        setState(() => _links = const []);
      }
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() => _pending = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'common:somethingWentWrong'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _move(int index, int direction) async {
    final links = _links;
    if (links == null) return;
    final target = index + direction;
    if (target < 0 || target >= links.length) return;
    final ids = [for (final link in links) link.id];
    final tmp = ids[index];
    ids[index] = ids[target];
    ids[target] = tmp;
    await _mutate(() => widget.settings.reorderWatchLinks(ids));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = _links;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedLink01,
      title: context.t('settings:watchLinks.title'),
      description: context.t('settings:watchLinks.description'),
      children: [
        if (links == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (links.isEmpty)
          Text(
            context.t('settings:watchLinks.empty'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < links.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _editingId == links[i].id
                  ? _WatchLinkForm(
                      submitLabel: context.t('common:save'),
                      pending: _pending,
                      initialLabel: links[i].label,
                      initialUrl: links[i].url,
                      initialContentTypes: links[i].contentTypes,
                      onCancel: () => setState(() => _editingId = null),
                      onSubmit: (label, url, types) => _mutate(() async {
                        await widget.settings.updateWatchLink(links[i].id, {
                          'label': label,
                          'url': url,
                          'contentTypes': types,
                        });
                        _editingId = null;
                      }),
                    )
                  : _WatchLinkRow(
                      link: links[i],
                      pending: _pending,
                      canMoveUp: i > 0,
                      canMoveDown: i < links.length - 1,
                      onToggle: (enabled) => _mutate(
                        () => widget.settings.updateWatchLink(links[i].id, {
                          'enabled': enabled,
                        }),
                      ),
                      onMoveUp: () => _move(i, -1),
                      onMoveDown: () => _move(i, 1),
                      onEdit: () => setState(() => _editingId = links[i].id),
                      onDelete: () => _mutate(
                        () => widget.settings.deleteWatchLink(links[i].id),
                      ),
                    ),
            ),
        if (links != null) ...[
          if (links.length >= maxWatchLinks)
            Text(
              context.t('settings:watchLinks.limitReached', {
                'count': maxWatchLinks,
              }),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            _WatchLinkForm(
              submitLabel: context.t('user:linksAddLink'),
              pending: _pending,
              onSubmit: (label, url, types) => _mutate(
                () => widget.settings.createWatchLink(
                  label: label,
                  url: url,
                  contentTypes: types,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _WatchLinkRow extends StatelessWidget {
  const _WatchLinkRow({
    required this.link,
    required this.pending,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final WatchLink link;
  final bool pending;
  final bool canMoveUp;
  final bool canMoveDown;
  final void Function(bool) onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  link.url,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final type in link.contentTypes)
                      if (watchLinkMediaTypeFromApi[type] != null)
                        _TypeBadge(type: watchLinkMediaTypeFromApi[type]!),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: link.enabled,
                    onChanged: pending
                        ? null
                        : (value) {
                            HapticsHelper.light();
                            onToggle(value);
                          },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    icon: HugeIcons.strokeRoundedArrowUp01,
                    label: context.t('user:setupMoveUp'),
                    onTap: canMoveUp && !pending ? onMoveUp : null,
                  ),
                  _IconAction(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    label: context.t('user:setupMoveDown'),
                    onTap: canMoveDown && !pending ? onMoveDown : null,
                  ),
                  _IconAction(
                    icon: HugeIcons.strokeRoundedPencil,
                    label: context.t('user:linksEditLink'),
                    onTap: pending ? null : onEdit,
                  ),
                  _IconAction(
                    icon: HugeIcons.strokeRoundedDelete02,
                    label: context.t('common:delete'),
                    onTap: pending ? null : onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final MediaType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: _typeIcons[type]!, size: 12),
          const SizedBox(width: 4),
          Text(
            context.t(_typeLabels[type]!),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, this.onTap});

  final dynamic icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      icon: HugeIcon(icon: icon, size: 18),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _WatchLinkForm extends StatefulWidget {
  const _WatchLinkForm({
    required this.submitLabel,
    required this.pending,
    this.initialLabel,
    this.initialUrl,
    this.initialContentTypes,
    this.onCancel,
    required this.onSubmit,
  });

  final String submitLabel;
  final bool pending;
  final String? initialLabel;
  final String? initialUrl;
  final List<String>? initialContentTypes;
  final VoidCallback? onCancel;
  final void Function(String label, String url, List<String> types) onSubmit;

  @override
  State<_WatchLinkForm> createState() => _WatchLinkFormState();
}

class _WatchLinkFormState extends State<_WatchLinkForm> {
  late final TextEditingController _label;
  late final TextEditingController _url;
  late Set<String> _types;
  bool _variablesOpen = false;
  String? _labelError;
  String? _urlError;
  String? _typesError;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initialLabel ?? '');
    _url = TextEditingController(text: widget.initialUrl ?? '');
    _types =
        widget.initialContentTypes?.toSet() ?? {'Movie', 'TVShow', 'Anime'};
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    super.dispose();
  }

  bool _validate() {
    final label = _label.text.trim();
    final url = _url.text.trim();
    setState(() {
      _labelError = label.isEmpty
          ? context.t('user:linkLabelRequired')
          : label.length > _labelMaxLength
          ? context.t('user:linkLabelMax')
          : null;
      _urlError = url.isEmpty
          ? context.t('settings:watchLinks.urlInvalid')
          : url.length > maxWatchLinkUrlLength
          ? context.t('settings:watchLinks.urlTooLong', {
              'count': maxWatchLinkUrlLength,
            })
          : !isSafeWatchLinkUrl(url)
          ? context.t('settings:watchLinks.urlInvalid')
          : watchLinkVariablesIn(url).any((v) => !isKnownWatchLinkVariable(v))
          ? context.t('settings:watchLinks.urlUnknownVariable')
          : null;
      _typesError = _types.isEmpty
          ? context.t('settings:watchLinks.contentTypesRequired')
          : null;
    });
    return _labelError == null && _urlError == null && _typesError == null;
  }

  void _insertVariable(String variable) {
    final token = '%$variable%';
    final value = _url.value;
    final start = value.selection.start < 0
        ? value.text.length
        : value.selection.start;
    final end = value.selection.end < 0
        ? value.text.length
        : value.selection.end;
    _url.value = TextEditingValue(
      text: value.text.replaceRange(start, end, token),
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _url.text.trim().isEmpty
        ? null
        : previewWatchLinkUrl(_url.text);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsFieldLabel(context.t('user:linkLabel')),
          const SizedBox(height: 4),
          TextField(
            controller: _label,
            enabled: !widget.pending,
            decoration: InputDecoration(
              hintText: context.t('settings:watchLinks.labelPlaceholder'),
              errorText: _labelError,
            ),
          ),
          const SizedBox(height: 12),
          SettingsFieldLabel(context.t('user:linkUrl')),
          const SizedBox(height: 4),
          TextField(
            controller: _url,
            enabled: !widget.pending,
            autocorrect: false,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'stremio://detail/movie/%ID_IMDB%',
              errorText: _urlError,
            ),
          ),
          const SizedBox(height: 12),
          SettingsFieldLabel(context.t('settings:contentTypes.title')),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            children: [
              for (final type in watchLinkMediaTypes)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _types.contains(watchLinkContentType[type]),
                      onChanged: widget.pending
                          ? null
                          : (checked) {
                              setState(() {
                                final api = watchLinkContentType[type]!;
                                if (checked == true) {
                                  _types.add(api);
                                } else {
                                  _types.remove(api);
                                }
                                _typesError = null;
                              });
                            },
                    ),
                    HugeIcon(
                      icon: _typeIcons[type]!,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(context.t(_typeLabels[type]!)),
                  ],
                ),
            ],
          ),
          if (_typesError != null) SettingsFieldError(_typesError!),
          if (preview != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${context.t('common:preview')}: $preview',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          InkWell(
            onTap: () => setState(() => _variablesOpen = !_variablesOpen),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: _variablesOpen
                        ? HugeIcons.strokeRoundedArrowDown01
                        : HugeIcons.strokeRoundedArrowRight01,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.t('settings:watchLinks.variablesTitle'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_variablesOpen)
            for (final variable in watchLinkVariables)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton(
                      onPressed: widget.pending
                          ? null
                          : () => _insertVariable(variable),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      child: Text('%$variable%'),
                    ),
                    Text(
                      watchLinkVariableExample(variable),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    for (final type
                        in watchLinkVariableSupport[variable] ??
                            const <MediaType>[])
                      Tooltip(
                        message: context.t(_typeLabels[type]!),
                        child: HugeIcon(
                          icon: _typeIcons[type]!,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.pending ? null : widget.onCancel,
                  child: Text(context.t('common:cancel')),
                ),
              FilledButton(
                onPressed: widget.pending
                    ? null
                    : () {
                        if (!_validate()) return;
                        widget.onSubmit(_label.text.trim(), _url.text.trim(), [
                          for (final type in watchLinkMediaTypes)
                            if (_types.contains(watchLinkContentType[type]))
                              watchLinkContentType[type]!,
                        ]);
                      },
                child: widget.pending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.submitLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
