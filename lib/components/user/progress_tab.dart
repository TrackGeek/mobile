import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../media/sliver_poster_grid.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/paginated_page.dart';
import '../../models/progress_item.dart';
import '../../services/progress_service.dart';
import '../../utils/content_types.dart';
import '../../utils/genres.dart';
import 'media_card.dart';
import 'user_widgets.dart';
import '../layout/tg_refresh_indicator.dart';
import '../../utils/adaptive_sheet_route.dart';
import '../../styles/tg_theme.dart';
import '../../utils/haptics.dart';
import '../../utils/numbers.dart';

class _ProgressContent {
  const _ProgressContent({
    required this.activeStatus,
    required this.activeLabelKey,
    this.repeatStatus,
    this.repeatLabelKey,
  });

  final String activeStatus;
  final String activeLabelKey;
  final String? repeatStatus;
  final String? repeatLabelKey;
}

const _progressContent = {
  MediaType.anime: _ProgressContent(
    activeStatus: 'Watching',
    activeLabelKey: 'watching',
    repeatStatus: 'Rewatching',
    repeatLabelKey: 'rewatching',
  ),
  MediaType.manga: _ProgressContent(
    activeStatus: 'Reading',
    activeLabelKey: 'reading',
    repeatStatus: 'Rereading',
    repeatLabelKey: 'rereading',
  ),
  MediaType.tv: _ProgressContent(
    activeStatus: 'Watching',
    activeLabelKey: 'watching',
    repeatStatus: 'Rewatching',
    repeatLabelKey: 'rewatching',
  ),
  MediaType.movie: _ProgressContent(
    activeStatus: 'Planning',
    activeLabelKey: 'planning',
  ),
  MediaType.game: _ProgressContent(
    activeStatus: 'Playing',
    activeLabelKey: 'playing',
    repeatStatus: 'Replaying',
    repeatLabelKey: 'replaying',
  ),
  MediaType.book: _ProgressContent(
    activeStatus: 'Reading',
    activeLabelKey: 'reading',
    repeatStatus: 'Rereading',
    repeatLabelKey: 'rereading',
  ),
};

const _statusIcons = {
  'Watching': HugeIcons.strokeRoundedPlay,
  'Playing': HugeIcons.strokeRoundedGameController01,
  'Reading': HugeIcons.strokeRoundedBookOpen01,
  'Planning': HugeIcons.strokeRoundedClock01,
  'Completed': HugeIcons.strokeRoundedCheckmarkCircle02,
  'Paused': HugeIcons.strokeRoundedPause,
  'Dropped': HugeIcons.strokeRoundedCancel01,
};

List<({String status, String labelKey})> _sections(MediaType type) {
  final config = _progressContent[type]!;
  return [
    (
      status: config.activeStatus,
      labelKey: 'feed:lists.${config.activeLabelKey}',
    ),
    if (config.repeatStatus != null)
      (
        status: config.repeatStatus!,
        labelKey: 'feed:lists.${config.repeatLabelKey}',
      ),
    if (config.activeStatus != 'Planning')
      (status: 'Planning', labelKey: 'feed:lists.planning'),
    (status: 'Completed', labelKey: 'feed:lists.completed'),
    (status: 'Paused', labelKey: 'feed:lists.paused'),
    (status: 'Dropped', labelKey: 'feed:lists.dropped'),
  ];
}

const progressTypeIcons = {
  MediaType.anime: HugeIcons.strokeRoundedMountain,
  MediaType.manga: HugeIcons.strokeRoundedBookOpen01,
  MediaType.tv: HugeIcons.strokeRoundedTv01,
  MediaType.movie: HugeIcons.strokeRoundedClapperboard,
  MediaType.game: HugeIcons.strokeRoundedGameController01,
  MediaType.book: HugeIcons.strokeRoundedBook01,
};

class TgMenuEntry<T> {
  const TgMenuEntry({
    required this.value,
    required this.icon,
    required this.label,
    this.count,
  });

  final T value;
  final List<List<dynamic>> icon;
  final String label;
  final int? count;
}

class TgMenuField<T> extends StatelessWidget {
  const TgMenuField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final List<List<dynamic>> icon;
  final String label;
  final T value;
  final List<TgMenuEntry<T>> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopupMenuButton<T>(
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                HugeIcon(
                  icon: item.icon,
                  size: 20,
                  color: item.value == value
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: item.value == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: item.value == value ? scheme.primary : null,
                    ),
                  ),
                ),
                if (item.count != null && item.count! > 0)
                  Text(
                    item.count!.humanizedCount(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(TgRadii.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge,
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

const _sortOptions = [
  ('name', 'user:sort.title'),
  ('addedAt', 'user:sort.lastAdded'),
  ('updatedAt', 'user:sort.lastUpdated'),
  ('releaseDate', 'common:releaseDate'),
];

class UserProgressTab extends StatefulWidget {
  const UserProgressTab({
    super.key,
    required this.userId,
    required this.session,
    required this.progress,
    required this.contentType,
    required this.onContentTypeChange,
    this.typeCounts = const {},
    this.onOpenMedia,
  });

  final String userId;
  final SessionController session;
  final ProgressService progress;
  final MediaType contentType;
  final ValueChanged<MediaType> onContentTypeChange;
  final Map<MediaType, int> typeCounts;
  final void Function(MediaType type, String slug)? onOpenMedia;

  @override
  State<UserProgressTab> createState() => _UserProgressTabState();
}

class _UserProgressTabState extends State<UserProgressTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <ProgressItem>[];
  final _search = TextEditingController();
  Timer? _debounce;
  String _status = 'Playing';
  Map<String, int> _statusCounts = const {};
  bool _loading = false;
  bool _loadingMore = false;
  bool _randomizing = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;
  String _sortBy = 'addedAt';
  String _sortOrder = 'desc';
  List<String> _completion = const [];
  List<String> _selectedPlatforms = const [];
  List<String> _availablePlatforms = const [];
  List<String> _genres = const [];
  String _year = '';
  bool? _released;
  List<String> _releaseStates = const [];
  final _options = ValueNotifier<ProgressFilterOptions?>(null);
  MediaType _type = MediaType.game;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _type = widget.contentType;
    _resetForType();
    _load();
    _loadOptions();
  }

  @override
  void didUpdateWidget(UserProgressTab old) {
    super.didUpdateWidget(old);
    if (widget.contentType != _type) {
      _type = widget.contentType;
      _resetForType();
      _load();
      _loadOptions();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _options.dispose();
    super.dispose();
  }

  void _resetForType() {
    _status = _progressContent[_type]!.activeStatus;
    _sortBy = 'addedAt';
    _sortOrder = 'desc';
    _search.clear();
    _completion = const [];
    _selectedPlatforms = const [];
    _availablePlatforms = const [];
    _genres = const [];
    _year = '';
    _released = null;
    _releaseStates = const [];
    _options.value = null;
  }

  String get _language => L10nScope.read(context).language;

  Future<PaginatedPage<ProgressItem>> _pageFetch(int page) async {
    final result = await widget.progress.userProgress(
      _type,
      userId: widget.userId,
      status: _status,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      completion: _completion,
      selectedPlatforms: _selectedPlatforms,
      availablePlatforms: _availablePlatforms,
      genres: _genres,
      year: _year,
      released: _released,
      releaseStates: _releaseStates,
      search: _search.text,
      page: page,
      language: _language,
    );
    _statusCounts = result.statusCounts;
    return result.page;
  }

  int _loadToken = 0;

  Future<void> _load() async {
    final token = ++_loadToken;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final page = await _pageFetch(1);
      if (token != _loadToken) return;
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (e) {
      if (token != _loadToken) return;
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    final token = _loadToken;
    setState(() => _loadingMore = true);
    try {
      final page = await _pageFetch(_page + 1);
      if (token != _loadToken) return;
      _items.addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (_) {
      // retry on next scroll
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadOptions() async {
    try {
      final type = _type;
      final options = await widget.progress.progressFilters(
        type,
        userId: widget.userId,
        language: _language,
      );
      if (mounted && type == _type) _options.value = options;
    } catch (_) {
      _options.value = null;
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _load);
  }

  Future<void> _random() async {
    if (_randomizing) return;
    setState(() => _randomizing = true);
    try {
      final first = await _pageFetchItems(1, itemsPerPage: 1);
      final total = first.total ?? 0;
      if (total > 0) {
        final randomPage = (DateTime.now().microsecondsSinceEpoch % total) + 1;
        final page = await _pageFetchItems(randomPage, itemsPerPage: 1);
        if (page.items.isNotEmpty && mounted) {
          final item = page.items.first;
          widget.onOpenMedia?.call(item.type, item.detailId);
        }
      }
    } catch (_) {
      // random pick failed silently; nothing to show
    } finally {
      if (mounted) setState(() => _randomizing = false);
    }
  }

  Future<PaginatedPage<ProgressItem>> _pageFetchItems(
    int page, {
    int itemsPerPage = 1,
  }) async => (await widget.progress.userProgress(
    _type,
    userId: widget.userId,
    status: _status,
    completion: _completion,
    selectedPlatforms: _selectedPlatforms,
    availablePlatforms: _availablePlatforms,
    genres: _genres,
    year: _year,
    released: _released,
    releaseStates: _releaseStates,
    search: _search.text,
    page: page,
    itemsPerPage: itemsPerPage,
    language: _language,
  )).page;

  int get _activeFilterCount =>
      (_completion.isNotEmpty ? 1 : 0) +
      (_selectedPlatforms.isNotEmpty ? 1 : 0) +
      (_availablePlatforms.isNotEmpty ? 1 : 0) +
      (_genres.isNotEmpty ? 1 : 0) +
      (RegExp(r'^\d{4}$').hasMatch(_year.trim()) ? 1 : 0) +
      (_released != null ? 1 : 0) +
      (_releaseStates.isNotEmpty ? 1 : 0);

  void _openFilters() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(
      _FiltersSheet(
        type: _type,
        status: _status,
        options: _options,
        completion: _completion,
        selectedPlatforms: _selectedPlatforms,
        availablePlatforms: _availablePlatforms,
        genres: _genres,
        year: _year,
        released: _released,
        releaseStates: _releaseStates,
        onChanged:
            ({
              completion = const <String>[],
              selectedPlatforms = const <String>[],
              availablePlatforms = const <String>[],
              genres = const <String>[],
              year = '',
              released,
              releaseStates = const <String>[],
            }) {
              setState(() {
                _completion = completion;
                _selectedPlatforms = selectedPlatforms;
                _availablePlatforms = availablePlatforms;
                _genres = genres;
                _year = year;
                _released = released;
                _releaseStates = releaseStates;
              });
              _load();
            },
      ).asAdaptiveSheetRoute<void>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewer = widget.session.user;
    final visible = visibleMediaTypes(viewer);
    final sections = _sections(_type);
    final hasQuery = _search.text.trim().isNotEmpty;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
          _loadMore();
        }
        return false;
      },
      child: TgRefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TgMenuField<MediaType>(
                            icon: progressTypeIcons[_type]!,
                            label: context.t(
                              'common:types.${_type.name}_other',
                            ),
                            value: _type,
                            items: [
                              for (final type in MediaType.values)
                                if (visible.contains(type))
                                  TgMenuEntry(
                                    value: type,
                                    icon: progressTypeIcons[type]!,
                                    label: context.t(
                                      'common:types.${type.name}_other',
                                    ),
                                    count: widget.typeCounts[type],
                                  ),
                            ],
                            onSelected: widget.onContentTypeChange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TgMenuField<String>(
                            icon:
                                _statusIcons[_status] ??
                                HugeIcons.strokeRoundedListView,
                            label: context.t(
                              sections
                                  .firstWhere(
                                    (s) => s.status == _status,
                                    orElse: () => sections.first,
                                  )
                                  .labelKey,
                            ),
                            value: _status,
                            items: [
                              for (final section in sections)
                                TgMenuEntry(
                                  value: section.status,
                                  icon:
                                      _statusIcons[section.status] ??
                                      HugeIcons.strokeRoundedListView,
                                  label: context.t(section.labelKey),
                                  count: _statusCounts[section.status] ?? 0,
                                ),
                            ],
                            onSelected: (status) {
                              setState(() {
                                _status = status;
                                if (_status != 'Completed' &&
                                    _status != 'Dropped') {
                                  _completion = const [];
                                }
                              });
                              _load();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => _onSearchChanged(),
                            decoration: InputDecoration(
                              hintText: context.t('common:search'),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 12, right: 8),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedSearch01,
                                  size: 18,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(),
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: Badge(
                            isLabelVisible: _activeFilterCount > 0,
                            label: Text(_activeFilterCount.humanizedCount()),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedFilterHorizontal,
                              size: 20,
                            ),
                          ),
                          tooltip: context.t('user:filter'),
                          onPressed: _openFilters,
                        ),
                        PopupMenuButton<String>(
                          tooltip: context.t('user:sort.title'),
                          icon: _randomizing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const HugeIcon(
                                  icon: HugeIcons.strokeRoundedMoreVertical,
                                  size: 20,
                                ),
                          onSelected: (value) {
                            if (value == 'random') {
                              _random();
                            } else if (value == 'order') {
                              setState(
                                () => _sortOrder = _sortOrder == 'asc'
                                    ? 'desc'
                                    : 'asc',
                              );
                              _load();
                            } else if (value != _sortBy) {
                              setState(() => _sortBy = value);
                              _load();
                            }
                          },
                          itemBuilder: (context) => [
                            for (final (value, key) in _sortOptions)
                              if (value != 'releaseDate' ||
                                  _type != MediaType.manga)
                                CheckedPopupMenuItem(
                                  value: value,
                                  checked: _sortBy == value,
                                  child: Text(context.t(key)),
                                ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'order',
                              child: Text(
                                _sortOrder == 'asc'
                                    ? context.t('common:ascending')
                                    : context.t('common:descending'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'random',
                              child: Text(context.t('user:random')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading && _items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _items.isEmpty)
              SliverFillRemaining(child: UserError(onRetry: _load))
            else if (_items.isEmpty)
              SliverFillRemaining(
                child: hasQuery || _activeFilterCount > 0
                    ? UserEmpty(
                        icon: HugeIcons.strokeRoundedSearch01,
                        title: context.t('common:noResults'),
                        description: context.t('common:noResultsDescription'),
                      )
                    : UserEmpty(
                        icon: HugeIcons.strokeRoundedChartLine,
                        title: context.t('user:noProgress'),
                        description: context.t('user:noProgressDescription'),
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverPosterGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= _items.length) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final item = _items[index];
                    return MediaCard(
                      title: item.title,
                      image: item.imageUrl ?? '',
                      year: item.year,
                      item: item,
                      onTap: () =>
                          widget.onOpenMedia?.call(item.type, item.detailId),
                    );
                  }, childCount: _items.length + (_loadingMore ? 1 : 0)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _releaseStateLabels = <MediaType, Map<String, String>>{
  MediaType.anime: {
    'Ongoing': 'library:statusAir.currentlyAiring',
    'Finished': 'library:statusAir.finishedAiring',
    'Hiatus': 'library:statusAir.onHiatus',
    'Unreleased': 'library:statusAir.notYetAired',
    'Cancelled': 'library:statusAir.discontinued',
  },
  MediaType.tv: {
    'Ongoing': 'library:statusAir.currentlyAiring',
    'Finished': 'library:statusAir.finishedAiring',
    'Hiatus': 'library:statusAir.onHiatus',
    'Unreleased': 'library:statusAir.notYetAired',
    'Cancelled': 'library:statusAir.discontinued',
  },
  MediaType.manga: {
    'Ongoing': 'library:statusAir.publishing',
    'Finished': 'library:statusAir.finished',
    'Hiatus': 'library:statusAir.onHiatus',
    'Unreleased': 'library:statusAir.notYetPublished',
    'Cancelled': 'library:statusAir.discontinued',
  },
  MediaType.book: {
    'Finished': 'library:statusAir.released',
    'Unreleased': 'library:statusAir.unreleased',
  },
  MediaType.movie: {},
  MediaType.game: {
    'Ongoing': 'library:statusAir.earlyAccess',
    'Cancelled': 'library:statusAir.discontinued',
  },
};

typedef _Option = ({String slug, String name});

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.type,
    required this.status,
    required this.options,
    required this.completion,
    required this.selectedPlatforms,
    required this.availablePlatforms,
    required this.genres,
    required this.year,
    required this.released,
    required this.releaseStates,
    required this.onChanged,
  });

  final MediaType type;
  final String status;
  final ValueListenable<ProgressFilterOptions?> options;
  final List<String> completion;
  final List<String> selectedPlatforms;
  final List<String> availablePlatforms;
  final List<String> genres;
  final String year;
  final bool? released;
  final List<String> releaseStates;
  final void Function({
    required List<String> completion,
    required List<String> selectedPlatforms,
    required List<String> availablePlatforms,
    required List<String> genres,
    required String year,
    required bool? released,
    required List<String> releaseStates,
  })
  onChanged;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late List<String> _completion = List.of(widget.completion);
  late List<String> _selected = List.of(widget.selectedPlatforms);
  late List<String> _available = List.of(widget.availablePlatforms);
  late List<String> _genres = List.of(widget.genres);
  late final _year = TextEditingController(text: widget.year);
  late bool? _released = widget.released;
  late List<String> _releaseStates = List.of(widget.releaseStates);

  static const _completions = [
    'mainStory',
    'mainStoryPlusExtras',
    '100%',
    'endless',
  ];

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  bool get _validYear => RegExp(r'^\d{4}$').hasMatch(_year.text.trim());

  int get _count =>
      (_completion.isNotEmpty ? 1 : 0) +
      (_selected.isNotEmpty ? 1 : 0) +
      (_available.isNotEmpty ? 1 : 0) +
      (_genres.isNotEmpty ? 1 : 0) +
      (_validYear ? 1 : 0) +
      (_released != null ? 1 : 0) +
      (_releaseStates.isNotEmpty ? 1 : 0);

  void _apply() {
    HapticsHelper.selection();
    widget.onChanged(
      completion: _completion,
      selectedPlatforms: _selected,
      availablePlatforms: _available,
      genres: _genres,
      year: _validYear ? _year.text.trim() : '',
      released: _released,
      releaseStates: _releaseStates,
    );
    Navigator.of(context).pop();
  }

  void _clear() => setState(() {
    _completion = [];
    _selected = [];
    _available = [];
    _genres = [];
    _year.clear();
    _released = null;
    _releaseStates = [];
  });

  void _toggle(List<String> list, String value) => setState(() {
    list.contains(value) ? list.remove(value) : list.add(value);
  });

  Future<void> _pick({
    required String title,
    required List<_Option> options,
    required List<String> current,
    required ValueChanged<List<String>> onDone,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _MultiSelectSheet(title: title, options: options, initial: current),
    );
    if (result != null) setState(() => onDone(result));
  }

  String _summary(List<String> values, List<_Option> options) {
    if (values.isEmpty) return context.t('user:filterAny');
    final names = [
      for (final o in options)
        if (values.contains(o.slug)) o.name,
    ];
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')} +${names.length - 2}';
  }

  Widget _pickerTile({
    required String title,
    required List<_Option> options,
    required List<String> values,
    required ValueChanged<List<String>> onDone,
  }) {
    final theme = Theme.of(context);
    final active = values.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: theme.textTheme.labelLarge),
      subtitle: Text(
        _summary(values, options),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _pick(
        title: title,
        options: options,
        current: values,
        onDone: onDone,
      ),
    );
  }

  Widget _group(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: title),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGame = widget.type == MediaType.game;
    final showCompletion =
        isGame && (widget.status == 'Completed' || widget.status == 'Dropped');
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  context.t('user:filter'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _count == 0 ? null : _clear,
                  child: Text(context.t('common:clear')),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<ProgressFilterOptions?>(
              valueListenable: widget.options,
              builder: (context, options, _) => ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (showCompletion)
                    _group(
                      context.t('feed:completionStatus.label'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final value in _completions)
                            FilterChip(
                              label: Text(
                                value == '100%'
                                    ? '100%'
                                    : context.t('feed:completionStatus.$value'),
                              ),
                              selected: _completion.contains(value),
                              onSelected: (_) => _toggle(_completion, value),
                            ),
                        ],
                      ),
                    ),
                  _group(
                    context.t('library:availability'),
                    SegmentedButton<bool?>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: null,
                          label: Text(context.t('common:all')),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(context.t('library:statusAir.released')),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text(
                            context.t('library:statusAir.unreleased'),
                          ),
                        ),
                      ],
                      selected: {_released},
                      onSelectionChanged: (v) =>
                          setState(() => _released = v.first),
                    ),
                  ),
                  if (options != null &&
                      options.releaseStates.length > 1 &&
                      options.releaseStates.any(
                        (s) => _releaseStateLabels[widget.type]?[s] != null,
                      ))
                    _group(
                      context.t('common:status'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final state in options.releaseStates)
                            if (_releaseStateLabels[widget.type]?[state] !=
                                null)
                              FilterChip(
                                label: Text(
                                  context.t(
                                    _releaseStateLabels[widget.type]![state]!,
                                  ),
                                ),
                                selected: _releaseStates.contains(state),
                                onSelected: (_) =>
                                    _toggle(_releaseStates, state),
                              ),
                        ],
                      ),
                    ),
                  _group(
                    context.t('library:year'),
                    TextField(
                      controller: _year,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        isDense: true,
                        counterText: '',
                        hintText: '2024',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (options == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    if (options.genres.isNotEmpty)
                      _pickerTile(
                        title: context.t('library:genres'),
                        options: [
                          for (final g in options.genres)
                            (slug: g, name: genreLabel(context, g)),
                        ],
                        values: _genres,
                        onDone: (v) => _genres = v,
                      ),
                    if (isGame && options.availablePlatforms.isNotEmpty)
                      _pickerTile(
                        title: context.t('library:availablePlatforms'),
                        options: options.availablePlatforms,
                        values: _available,
                        onDone: (v) => _available = v,
                      ),
                    if (showCompletion && options.selectedPlatforms.isNotEmpty)
                      _pickerTile(
                        title: context.t('library:selectedPlatforms'),
                        options: options.selectedPlatforms,
                        values: _selected,
                        onDone: (v) => _selected = v,
                      ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: Text(
                  _count == 0
                      ? context.t('user:filterApply')
                      : context.t('user:filterApplyCount', {
                          'count': _count,
                          'formattedCount': _count.humanizedCount(),
                        }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<_Option> options;
  final List<String> initial;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final _selected = <String>{...widget.initial};
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.text.trim().toLowerCase();
    final shown = [
      for (final o in widget.options)
        if (q.isEmpty || o.name.toLowerCase().contains(q)) o,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => setState(_selected.clear),
                    child: Text(context.t('common:clear')),
                  ),
                ],
              ),
            ),
            if (widget.options.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.t('common:search'),
                    isDense: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 18,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                  ),
                ),
              ),
            Expanded(
              child: shown.isEmpty
                  ? Center(child: Text(context.t('common:noResults')))
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final o = shown[i];
                        return CheckboxListTile(
                          dense: true,
                          controlAffinity: ListTileControlAffinity.trailing,
                          title: Text(o.name),
                          value: _selected.contains(o.slug),
                          onChanged: (v) => setState(() {
                            v == true
                                ? _selected.add(o.slug)
                                : _selected.remove(o.slug);
                          }),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop([
                    for (final o in widget.options)
                      if (_selected.contains(o.slug)) o.slug,
                  ]),
                  child: Text(
                    _selected.isEmpty
                        ? context.t('user:filterConfirm')
                        : context.t('user:filterConfirmCount', {
                            'count': _selected.length,
                            'formattedCount': _selected.length.humanizedCount(),
                          }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}
