import 'dart:async';

import 'package:flutter/material.dart';

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
import '../layout/edgy.dart';
import '../layout/tg_refresh_indicator.dart';
import '../../utils/adaptive_sheet_route.dart';

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
    this.onOpenMedia,
  });

  final String userId;
  final SessionController session;
  final ProgressService progress;
  final MediaType contentType;
  final ValueChanged<MediaType> onContentTypeChange;
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
  ProgressFilterOptions? _options;
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
    _options = null;
  }

  String get _language => L10nScope.of(context).language;

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

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _pageFetch(1);
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _pageFetch(_page + 1);
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
      _options = await widget.progress.progressFilters(
        _type,
        userId: widget.userId,
        language: _language,
      );
    } catch (_) {
      _options = null;
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
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), _load);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: Edgy(
                      axis: .horizontal,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: MediaType.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final type = MediaType.values[index];
                          if (!visible.contains(type)) {
                            return const SizedBox.shrink();
                          }
                          return ChoiceChip(
                            label: Text(
                              context.t('common:types.${type.name}_other'),
                            ),
                            selected: _type == type,
                            onSelected: (_) => widget.onContentTypeChange(type),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Edgy(
                      axis: .horizontal,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sections.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final section = sections[index];
                          final count = _statusCounts[section.status] ?? 0;
                          return ChoiceChip(
                            avatar: HugeIcon(
                              icon:
                                  _statusIcons[section.status] ??
                                  HugeIcons.strokeRoundedListView,
                              size: 14,
                            ),
                            label: Text(
                              count > 0
                                  ? '${context.t(section.labelKey)}, $count'
                                  : context.t(section.labelKey),
                            ),
                            selected: _status == section.status,
                            onSelected: (_) {
                              setState(() {
                                _status = section.status;
                                if (_status != 'Completed' &&
                                    _status != 'Dropped') {
                                  _completion = const [];
                                }
                              });
                              _load();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => _onSearchChanged(),
                            decoration: InputDecoration(
                              hintText: context.t('common:search'),
                              prefixIcon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedSearch01,
                                size: 18,
                              ),
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: _randomizing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const HugeIcon(
                                  icon: HugeIcons.strokeRoundedShuffle,
                                  size: 16,
                                ),
                          tooltip: context.t('user:random'),
                          onPressed: _random,
                        ),
                        const SizedBox(width: 4),
                        IconButton.filledTonal(
                          icon: Badge(
                            isLabelVisible: _activeFilterCount > 0,
                            label: Text('$_activeFilterCount'),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedFilterHorizontal,
                              size: 16,
                            ),
                          ),
                          tooltip: context.t('user:filter'),
                          onPressed: _openFilters,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sortBy,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final (value, key) in _sortOptions)
                                if (value != 'releaseDate' ||
                                    _type != MediaType.manga)
                                  DropdownMenuItem(
                                    value: value,
                                    child: Text(context.t(key)),
                                  ),
                            ],
                            onChanged: (value) {
                              if (value == null || value == _sortBy) return;
                              setState(() => _sortBy = value);
                              _load();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: HugeIcon(
                            icon: _sortOrder == 'asc'
                                ? HugeIcons.strokeRoundedSortByUp02
                                : HugeIcons.strokeRoundedSortByDown02,
                            size: 16,
                          ),
                          tooltip: _sortOrder == 'asc'
                              ? context.t('common:ascending')
                              : context.t('common:descending'),
                          onPressed: () {
                            setState(
                              () => _sortOrder = _sortOrder == 'asc'
                                  ? 'desc'
                                  : 'asc',
                            );
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
  final ProgressFilterOptions? options;
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

  void _emit() => widget.onChanged(
    completion: _completion,
    selectedPlatforms: _selected,
    availablePlatforms: _available,
    genres: _genres,
    year: _year.text,
    released: _released,
    releaseStates: _releaseStates,
  );

  void _toggle(List<String> list, String value) => setState(() {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    _emit();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = widget.options;
    final isGame = widget.type == MediaType.game;
    final showCompletion =
        isGame && (widget.status == 'Completed' || widget.status == 'Dropped');
    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                context.t('user:filter'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _completion = [];
                    _selected = [];
                    _available = [];
                    _genres = [];
                    _year.clear();
                    _released = null;
                    _releaseStates = [];
                  });
                  _emit();
                },
                child: Text(context.t('common:clear')),
              ),
            ],
          ),
          if (options == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (showCompletion) ...[
              _SectionTitle(text: context.t('feed:completionStatus.label')),
              Wrap(
                spacing: 8,
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
              const SizedBox(height: 12),
            ],
            if (isGame &&
                showCompletion &&
                options.selectedPlatforms.isNotEmpty) ...[
              _SectionTitle(text: context.t('library:selectedPlatforms')),
              Wrap(
                spacing: 8,
                children: [
                  for (final platform in options.selectedPlatforms)
                    FilterChip(
                      label: Text(platform.name),
                      selected: _selected.contains(platform.slug),
                      onSelected: (_) => _toggle(_selected, platform.slug),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (isGame && options.availablePlatforms.isNotEmpty) ...[
              _SectionTitle(text: context.t('library:availablePlatforms')),
              Wrap(
                spacing: 8,
                children: [
                  for (final platform in options.availablePlatforms)
                    FilterChip(
                      label: Text(platform.name),
                      selected: _available.contains(platform.slug),
                      onSelected: (_) => _toggle(_available, platform.slug),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (options.genres.isNotEmpty) ...[
              _SectionTitle(text: context.t('library:genres')),
              Wrap(
                spacing: 8,
                children: [
                  for (final genre in options.genres)
                    FilterChip(
                      label: Text(genreLabel(context, genre)),
                      selected: _genres.contains(genre),
                      onSelected: (_) => _toggle(_genres, genre),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            _SectionTitle(text: context.t('library:year')),
            TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                counterText: '',
              ),
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 12),
            _SectionTitle(text: context.t('library:availability')),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(context.t('common:all')),
                  selected: _released == null,
                  onSelected: (_) => setState(() {
                    _released = null;
                    _emit();
                  }),
                ),
                ChoiceChip(
                  label: Text(context.t('library:statusAir.released')),
                  selected: _released == true,
                  onSelected: (_) => setState(() {
                    _released = true;
                    _emit();
                  }),
                ),
                ChoiceChip(
                  label: Text(context.t('library:statusAir.unreleased')),
                  selected: _released == false,
                  onSelected: (_) => setState(() {
                    _released = false;
                    _emit();
                  }),
                ),
              ],
            ),
            if (options.releaseStates.length > 1) ...[
              const SizedBox(height: 12),
              _SectionTitle(text: context.t('common:status')),
              Wrap(
                spacing: 8,
                children: [
                  for (final state in options.releaseStates)
                    if (_releaseStateLabels[widget.type]?[state] != null)
                      FilterChip(
                        label: Text(
                          context.t(_releaseStateLabels[widget.type]![state]!),
                        ),
                        selected: _releaseStates.contains(state),
                        onSelected: (_) => _toggle(_releaseStates, state),
                      ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}
