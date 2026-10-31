import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../services/genre_service.dart';
import '../../styles/tg_theme.dart';
import '../../utils/genres.dart';

class _Option {
  const _Option(this.value, {this.labelKey, this.label});

  final String value;
  final String? labelKey;
  final String? label;

  String resolve(BuildContext context) =>
      labelKey != null ? context.t(labelKey!) : label ?? value;
}

const _typeOptions = <MediaType, List<_Option>>{
  MediaType.anime: [
    _Option('tv', labelKey: 'common:types.tv'),
    _Option('movie', labelKey: 'common:types.movie'),
    _Option('ova', label: 'OVA'),
    _Option('ona', label: 'ONA'),
    _Option('special', labelKey: 'library:types.Special'),
    _Option('tv_special', labelKey: 'library:types.TVSpecial'),
    _Option('music', labelKey: 'library:types.Music'),
    _Option('cm', label: 'CM'),
    _Option('pv', label: 'PV'),
  ],
  MediaType.manga: [
    _Option('manga', labelKey: 'common:types.manga'),
    _Option('novel', labelKey: 'library:types.Novel'),
    _Option('lightnovel', labelKey: 'library:types.LightNovel'),
    _Option('oneshot', labelKey: 'library:types.OneShot'),
    _Option('doujin', labelKey: 'library:types.Doujinshi'),
    _Option('manhwa', labelKey: 'library:types.Manhwa'),
    _Option('manhua', labelKey: 'library:types.Manhua'),
  ],
};

const _statusOptions = <MediaType, List<_Option>>{
  MediaType.anime: [
    _Option('upcoming', labelKey: 'library:statusAir.notYetAired'),
    _Option('airing', labelKey: 'library:statusAir.currentlyAiring'),
    _Option('complete', labelKey: 'library:statusAir.finishedAiring'),
  ],
  MediaType.manga: [
    _Option('upcoming', labelKey: 'library:statusAir.notYetPublished'),
    _Option('publishing', labelKey: 'library:statusAir.publishing'),
    _Option('complete', labelKey: 'library:statusAir.finished'),
    _Option('hiatus', labelKey: 'library:statusAir.onHiatus'),
    _Option('discontinued', labelKey: 'library:statusAir.discontinued'),
  ],
  MediaType.game: [
    _Option('Released', labelKey: 'library:statusAir.released'),
    _Option('Not Released', labelKey: 'library:statusAir.unreleased'),
    _Option('Early Access', labelKey: 'library:statusAir.earlyAccess'),
    _Option('Alpha', labelKey: 'library:statusAir.alpha'),
    _Option('Beta', labelKey: 'library:statusAir.beta'),
    _Option('Delisted', labelKey: 'library:statusAir.delisted'),
    _Option('Offline', labelKey: 'library:statusAir.offline'),
    _Option('Cancelled', labelKey: 'library:statusAir.cancelled'),
    _Option('Rumored', labelKey: 'library:statusAir.rumored'),
  ],
};

const _sortOptions = <MediaType, List<_Option>>{
  MediaType.anime: [
    _Option('score', labelKey: 'common:rating'),
    _Option('title', labelKey: 'user:sort.title'),
    _Option('start_date', labelKey: 'common:releaseDate'),
    _Option('end_date', labelKey: 'user:sort.endDate'),
    _Option('type', labelKey: 'library:type'),
  ],
  MediaType.manga: [
    _Option('score', labelKey: 'common:rating'),
    _Option('title', labelKey: 'user:sort.title'),
    _Option('start_date', labelKey: 'common:releaseDate'),
    _Option('end_date', labelKey: 'user:sort.endDate'),
    _Option('popularity', labelKey: 'user:sort.popularity'),
  ],
  MediaType.game: [
    _Option('popularity', labelKey: 'user:sort.popularity'),
    _Option('total_rating', labelKey: 'common:rating'),
    _Option('name', labelKey: 'user:sort.title'),
    _Option('first_release_date', labelKey: 'common:releaseDate'),
  ],
  MediaType.movie: [
    _Option('score', labelKey: 'common:rating'),
    _Option('title', labelKey: 'user:sort.title'),
    _Option('release_date', labelKey: 'common:releaseDate'),
  ],
  MediaType.tv: [
    _Option('score', labelKey: 'common:rating'),
    _Option('name', labelKey: 'user:sort.title'),
    _Option('first_air_date', labelKey: 'common:releaseDate'),
  ],
  MediaType.book: [
    _Option('rating', labelKey: 'common:rating'),
    _Option('title', labelKey: 'user:sort.title'),
    _Option('release_date', labelKey: 'common:releaseDate'),
  ],
};

const _gameModeOptions = [
  _Option('single-player', labelKey: 'library:gameModesList.singleplayer'),
  _Option('multiplayer', labelKey: 'library:gameModesList.multiplayer'),
  _Option('co-operative', labelKey: 'library:gameModesList.cooperative'),
  _Option('split-screen', labelKey: 'library:gameModesList.splitscreen'),
  _Option(
    'massively-multiplayer-online-mmo',
    labelKey: 'library:gameModesList.massivelyMultiplayerOnline',
  ),
  _Option('battle-royale', labelKey: 'library:gameModesList.battleRoyale'),
];

const _platforms = [
  'Nintendo Switch 2',
  'PlayStation 5',
  'Xbox Series X|S',
  'PC (Microsoft Windows)',
  'Nintendo Switch',
  'PlayStation 4',
  'Xbox One',
  'Mac',
  'Linux',
  'Android',
  'iOS',
  'visionOS',
  'Meta Quest 3',
  'Meta Quest 2',
  'PlayStation VR2',
  'PlayStation VR',
  'Oculus Rift',
  'Oculus Quest',
  'Oculus Go',
  'Gear VR',
  'Arcade',
  'New Nintendo 3DS',
  'Nintendo 3DS',
  'Nintendo DSi',
  'Nintendo DS',
  'Wii U',
  'Wii',
  'Nintendo GameCube',
  'Nintendo 64',
  'Super Nintendo Entertainment System',
  'Nintendo Entertainment System',
  'Game Boy Advance',
  'Game Boy Color',
  'Game Boy',
  'Virtual Boy',
  'PlayStation 3',
  'PlayStation 2',
  'PlayStation',
  'PlayStation Vita',
  'PlayStation Portable',
  'Xbox 360',
  'Xbox',
  'Dreamcast',
  'Sega Saturn',
  'Sega Mega Drive/Genesis',
  'Sega Master System/Mark III',
  'Sega Game Gear',
  'Sega CD',
  'Sega 32X',
  'Atari 2600',
  'Atari 5200',
  'Atari 7800',
  'Atari Jaguar',
  'Atari Lynx',
  'Atari ST/STE',
  'Amiga',
  'Commodore C64/128/MAX',
  'ZX Spectrum',
  'Amstrad CPC',
  'MSX',
  'MSX2',
  'DOS',
  'Neo Geo AES',
  'Neo Geo MVS',
  'Neo Geo Pocket',
  'Neo Geo Pocket Color',
  'TurboGrafx-16/PC Engine',
  'Turbografx-16/PC Engine CD',
  'WonderSwan',
  'WonderSwan Color',
  'Philips CD-i',
  '3DO Interactive Multiplayer',
  'ColecoVision',
  'Intellivision',
  'Vectrex',
  'Apple II',
  'Playdate',
  'Evercade',
  'Ouya',
  'Windows Phone',
  'Legacy Mobile Device',
  'Blu-ray Player',
  'DVD Player',
];

({int min, int max}) _yearRange(MediaType type) {
  final now = DateTime.now().year;
  return switch (type) {
    MediaType.anime => (min: 1958, max: now + 2),
    MediaType.manga => (min: 1858, max: now + 2),
    MediaType.book => (min: -3000, max: now),
    MediaType.game => (min: 1958, max: now + 2),
    MediaType.movie => (min: 1888, max: now + 2),
    MediaType.tv => (min: 1927, max: now + 2),
  };
}

class SearchFilters extends StatefulWidget {
  const SearchFilters({
    super.key,
    required this.type,
    required this.values,
    required this.onChanged,
    required this.onClear,
    required this.genreService,
  });

  final MediaType type;
  final Map<String, String> values;
  final void Function(String key, String? value) onChanged;
  final VoidCallback onClear;
  final GenreService genreService;

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  static const _gap = 20.0;

  final _year = TextEditingController();

  @override
  void initState() {
    super.initState();
    _year.text = widget.values['year'] ?? '';
  }

  @override
  void didUpdateWidget(SearchFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.values['year'] ?? '') != _year.text) {
      _year.text = widget.values['year'] ?? '';
    }
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  List<String> _listValue(String key) {
    final raw = widget.values[key];
    if (raw == null || raw.isEmpty) return const [];
    return raw.split(',');
  }

  Widget _labeled(String title, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_FieldLabel(title), child],
  );

  Widget _select(String title, String key, List<_Option> options) {
    final current = widget.values[key];
    final selected = options.where((o) => o.value == current).firstOrNull;
    return _labeled(
      title,
      _MenuField(
        display: selected?.resolve(context) ?? context.t('common:all'),
        active: selected != null,
        itemsBuilder: (close) => [
          for (final option in [
            _Option('', label: context.t('common:all')),
            ...options,
          ])
            MenuItemButton(
              leadingIcon: SizedBox(
                width: 16,
                child: option.value == (current ?? '')
                    ? HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              onPressed: () => widget.onChanged(
                key,
                option.value.isEmpty ? null : option.value,
              ),
              child: Text(option.resolve(context)),
            ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> children) => children.length == 1
      ? children.first
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [for (final child in children) Expanded(child: child)],
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = widget.values.values.where((v) => v.isNotEmpty).length;
    final rating = double.tryParse(widget.values['minTgScore'] ?? '') ?? 0;
    final yearRange = _yearRange(widget.type);
    final typeOptions = _typeOptions[widget.type];
    final statusOptions = _statusOptions[widget.type];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.t('user:filter'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (activeCount > 0) ...[
                Badge.count(count: activeCount),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onClear,
                  child: Text(context.t('common:clear')),
                ),
              ],
            ],
          ),
          const SizedBox(height: _gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel(context.t('common:rating')),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  rating > 0
                      ? '≥ ${rating.toStringAsFixed(1)}'
                      : context.t('common:all'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: rating > 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            min: 0,
            max: 5,
            divisions: 10,
            value: rating,
            label: rating.toStringAsFixed(1),
            onChanged: (v) => widget.onChanged(
              'minTgScore',
              v <= 0 ? null : v.toStringAsFixed(1),
            ),
          ),
          const SizedBox(height: _gap - 8),
          if (typeOptions != null || statusOptions != null) ...[
            _row([
              if (typeOptions != null)
                _select(context.t('library:type'), 'type', typeOptions),
              if (statusOptions != null)
                _select(context.t('common:status'), 'status', statusOptions),
            ]),
            const SizedBox(height: _gap),
          ],
          _GenreFilter(
            type: widget.type,
            service: widget.genreService,
            selected: _listValue('genres'),
            onChanged: (v) =>
                widget.onChanged('genres', v.isEmpty ? null : v.join(',')),
          ),
          const SizedBox(height: _gap),
          if (widget.type == MediaType.game) ...[
            _MultiSelect(
              title: context.t('library:platforms'),
              options: _platforms,
              selected: _listValue('platforms'),
              labelOf: (v) => v,
              onChanged: (v) =>
                  widget.onChanged('platforms', v.isEmpty ? null : v.join(',')),
            ),
            const SizedBox(height: _gap),
            _select(
              context.t('library:gameModes'),
              'gameMode',
              _gameModeOptions,
            ),
            const SizedBox(height: _gap),
          ],
          _row([
            _labeled(
              context.t('library:year'),
              TextField(
                controller: _year,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  hintText: '${yearRange.min} – ${yearRange.max}',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                onChanged: (v) =>
                    widget.onChanged('year', v.isEmpty ? null : v),
              ),
            ),
            _select(
              context.t('user:sort.placeholder'),
              'orderBy',
              _sortOptions[widget.type]!,
            ),
          ]),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _MenuField extends StatelessWidget {
  const _MenuField({
    required this.display,
    required this.itemsBuilder,
    this.active = false,
    this.enabled = true,
  });

  final String display;
  final bool active;
  final bool enabled;
  final List<Widget> Function(VoidCallback close) itemsBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MenuAnchor(
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(TgColors.overlay),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            minimumSize: WidgetStatePropertyAll(Size(width, 0)),
            maximumSize: WidgetStatePropertyAll(Size(width, 320)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          menuChildren: itemsBuilder(() {}),
          builder: (context, controller, _) => Material(
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: active
                    ? theme.colorScheme.primary.withValues(alpha: 0.6)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled
                  ? () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      controller.isOpen
                          ? controller.close()
                          : controller.open();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        display,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: active || !enabled
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenreFilter extends StatefulWidget {
  const _GenreFilter({
    required this.type,
    required this.service,
    required this.selected,
    required this.onChanged,
  });

  final MediaType type;
  final GenreService service;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_GenreFilter> createState() => _GenreFilterState();
}

class _GenreFilterState extends State<_GenreFilter> {
  List<String>? _remote;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_GenreFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) _load();
  }

  Future<void> _load() async {
    if (!GenreService.hasRemoteGenres(widget.type)) {
      setState(() {
        _remote = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final result = await widget.service.genres(widget.type);
    if (!mounted) return;
    setState(() {
      _remote = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = _remote ?? staticGenres[widget.type] ?? const <String>[];
    return _MultiSelect(
      title: context.t('library:genres'),
      options: options,
      selected: widget.selected,
      labelOf: (v) => genreLabel(context, v),
      enabled: !_loading,
      onChanged: widget.onChanged,
    );
  }
}

class _MultiSelect extends StatelessWidget {
  const _MultiSelect({
    required this.title,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final List<String> options;
  final List<String> selected;
  final String Function(String) labelOf;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  void _toggle(String option) {
    final next = {...selected};
    if (!next.remove(option)) next.add(option);
    onChanged(options.where(next.contains).toList());
  }

  @override
  Widget build(BuildContext context) {
    final String display;
    if (!enabled) {
      display = context.t('common:loading');
    } else if (selected.isEmpty) {
      display = context.t('common:all');
    } else {
      display = selected.length == 1
          ? labelOf(selected.first)
          : '${labelOf(selected.first)} +${selected.length - 1}';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(title),
        _MenuField(
          display: display,
          active: selected.isNotEmpty,
          enabled: enabled,
          itemsBuilder: (_) => [
            for (final option in options)
              CheckboxMenuButton(
                closeOnActivate: false,
                value: selected.contains(option),
                onChanged: (_) => _toggle(option),
                child: Text(labelOf(option)),
              ),
          ],
        ),
        if (selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in selected)
                  InputChip(
                    label: Text(labelOf(value)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIcon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 14,
                    ),
                    onDeleted: () => _toggle(value),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
