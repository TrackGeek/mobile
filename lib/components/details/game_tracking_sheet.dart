import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n_context.dart';
import '../../models/game_detail.dart';
import '../../models/game_screenshot.dart';
import '../../models/media_type.dart';
import '../../models/review.dart';
import '../../models/user_list.dart';
import '../../services/game_service.dart';
import '../../services/list_service.dart';
import '../../services/review_service.dart';
import '../../utils/dates.dart';
import '../../utils/video_links.dart';
import '../user/star_rating.dart';
import 'tracking_sheet.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';
import '../../utils/adaptive_sheet_route.dart';

const _statusOptions = [
  'planning',
  'playing',
  'played',
  'replaying',
  'dropped',
  'paused',
];

const _statusToEnum = {
  'planning': 'Planning',
  'playing': 'Playing',
  'played': 'Completed',
  'replaying': 'Replaying',
  'dropped': 'Dropped',
  'paused': 'Paused',
};

const _enumToStatus = {
  'Planning': 'planning',
  'Playing': 'playing',
  'Replaying': 'replaying',
  'Completed': 'played',
  'Paused': 'paused',
  'Dropped': 'dropped',
};

const _completionOptions = [
  'mainStory',
  'mainStoryPlusExtras',
  '100%',
  'endless',
];

const _reviewShownStatuses = {'played', 'dropped', 'replaying'};
const _reviewSavedStatuses = {'played', 'dropped'};
const _recommendedThreshold = 2.5;
const _summaryMax = 500;
const _reviewNotesMax = 10000;
const _progressNotesMax = 1000;
const _screenshotDescriptionMax = 255;
const _screenshotMaxBytes = 5 * 1024 * 1024;
final _screenshotExtensions = RegExp(
  r'\.(jpe?g|png|gif|webp)$',
  caseSensitive: false,
);

class GameTrackingSheet extends StatefulWidget {
  const GameTrackingSheet({
    super.key,
    required this.game,
    required this.gameService,
    required this.reviews,
    required this.lists,
    required this.userId,
    required this.unreleased,
    required this.progress,
    required this.ownReview,
    required this.userLists,
    required this.listStatus,
    this.isFavorited = false,
    this.favoriteBusy = false,
    this.onToggleFavorite,
    this.onChanged,
  });

  final GameDetail game;
  final GameService gameService;
  final ReviewService reviews;
  final ListService lists;
  final String userId;
  final bool unreleased;
  final GameProgress? progress;
  final UserReview? ownReview;
  final List<UserList> userLists;
  final List<String> listStatus;
  final bool isFavorited;
  final bool favoriteBusy;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onChanged;

  static Future<void> open(
    BuildContext context, {
    required GameDetail game,
    required GameService gameService,
    required ReviewService reviews,
    required ListService lists,
    required String userId,
    required bool unreleased,
    required GameProgress? progress,
    required UserReview? ownReview,
    required List<UserList> userLists,
    required List<String> listStatus,
    bool isFavorited = false,
    bool favoriteBusy = false,
    VoidCallback? onToggleFavorite,
    VoidCallback? onChanged,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    return Navigator.of(context).push<void>(
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GameTrackingSheet(
          game: game,
          gameService: gameService,
          reviews: reviews,
          lists: lists,
          userId: userId,
          unreleased: unreleased,
          progress: progress,
          ownReview: ownReview,
          userLists: userLists,
          listStatus: listStatus,
          isFavorited: isFavorited,
          favoriteBusy: favoriteBusy,
          onToggleFavorite: onToggleFavorite,
          onChanged: onChanged,
        ),
      ).asAdaptiveSheetRoute<void>(),
    );
  }

  @override
  State<GameTrackingSheet> createState() => _GameTrackingSheetState();
}

class _GameTrackingSheetState extends State<GameTrackingSheet> {
  late String _status;
  String _completion = '';
  late Set<String> _platforms;
  late final TextEditingController _hoursPlayed;
  late final TextEditingController _playCount;
  late final TextEditingController _progressNotes;
  late final TextEditingController _summary;
  late final TextEditingController _reviewNotes;
  late double _overall;
  late final Map<String, double> _criteria;
  late bool _recommended;
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _saving = false;
  bool _deleting = false;
  bool _error = false;

  List<GamePlatform> get _platformOptions => [
    for (final p in widget.game.platforms)
      if (p.name.isNotEmpty && p.slug.isNotEmpty) p,
  ];

  DateTime? get _minStartDate {
    final parsed = DateTime.tryParse(widget.game.firstReleaseDate ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(ensureDateLocale(L10nScope.of(context).language));
  }

  @override
  void initState() {
    super.initState();
    final progress = widget.progress;
    _status = _enumToStatus[progress?.status] ?? '';
    _completion = progress?.completion ?? '';
    final nameBySlug = {
      for (final p in _platformOptions) p.slug.toLowerCase(): p.name,
    };
    _platforms = {
      for (final slug in progress?.platforms ?? const <String>[])
        if (nameBySlug[slug.toLowerCase()] != null)
          nameBySlug[slug.toLowerCase()]!,
    };
    _hoursPlayed = TextEditingController(
      text: progress?.hoursPlayed?.toString() ?? '',
    );
    _playCount = TextEditingController(
      text: progress?.playCount?.toString() ?? '',
    );
    _progressNotes = TextEditingController(text: progress?.notes ?? '');
    _startDate = DateTime.tryParse(progress?.startedAt ?? '');
    _finishDate = DateTime.tryParse(progress?.completedAt ?? '');
    final review = widget.ownReview;
    _overall = review?.overall ?? 0;
    _criteria = {
      for (final key in reviewContent[MediaType.game]!.criteria)
        key: review?.fields[key] ?? 0,
    };
    _summary = TextEditingController(text: review?.summary ?? '');
    _reviewNotes = TextEditingController(text: review?.notes ?? '');
    _recommended = review?.recommended ?? false;
  }

  @override
  void dispose() {
    _hoursPlayed.dispose();
    _playCount.dispose();
    _progressNotes.dispose();
    _summary.dispose();
    _reviewNotes.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minStart = _minStartDate;
    final firstDate = start
        ? (minStart ?? DateTime(1900))
        : ([minStart, _startDate].whereType<DateTime>().fold<DateTime?>(
                null,
                (latest, d) => latest == null || d.isAfter(latest) ? d : latest,
              ) ??
              DateTime(1900));
    final lastDate = start ? DateTime(now.year + 10) : today;
    var initial = (start ? _startDate : _finishDate) ?? today;
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() => start ? _startDate = picked : _finishDate = picked);
    }
  }

  Future<void> _pickPlatforms() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PlatformPickerDialog(
        options: _platformOptions,
        selected: _platforms,
      ),
    );
    if (selected != null) setState(() => _platforms = selected);
  }

  Future<void> _save() async {
    if (_status.isEmpty || _saving) {
      if (_status.isEmpty) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      final statusEnum = _statusToEnum[_status]!;
      final notes = _progressNotes.text.trim();
      await widget.gameService.saveProgress(
        widget.game.id,
        status: statusEnum,
        playCount: int.tryParse(_playCount.text.trim()),
        completion: _completion.isEmpty ? null : _completion,
        platforms: _platformOptions.isNotEmpty ? _platforms.toList() : null,
        hoursPlayed: int.tryParse(_hoursPlayed.text.trim()),
        notes: notes.isEmpty ? null : notes,
        startedAt: _startDate?.toIso8601String(),
        completedAt: statusEnum == 'Completed'
            ? (_finishDate ?? DateTime.now()).toIso8601String()
            : _finishDate?.toIso8601String(),
      );
      if (_reviewSavedStatuses.contains(_status) && _overall > 0) {
        final reviewNotes = _reviewNotes.text.trim();
        final summary = _summary.text.trim();
        final fields = <String, Object?>{
          'overall': _overall,
          if (summary.isNotEmpty) 'summary': summary,
          if (reviewNotes.isNotEmpty) 'notes': reviewNotes,
          'recommended': _recommended,
          for (final entry in _criteria.entries)
            if (entry.value > 0) entry.key: entry.value,
        };
        final existing = widget.ownReview;
        if (existing != null) {
          await widget.reviews.updateReview(existing, fields: fields);
        } else {
          await widget.reviews.createReview(
            MediaType.game,
            mediaId: widget.game.id,
            fields: fields,
          );
        }
      }
      widget.onChanged?.call();
      HapticsHelper.success();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      HapticsHelper.error();
      if (mounted) {
        setState(() {
          _saving = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.t('feed:removeConfirmTitle')),
        content: Text(context.t('feed:removeConfirmDescription')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('common:cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('feed:removeConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.gameService.resetTracking(widget.game.id);
      widget.onChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = widget.unreleased ? const ['planning'] : _statusOptions;
    final showReview =
        _reviewShownStatuses.contains(_status) && !widget.unreleased;
    final canDelete = widget.progress != null || widget.ownReview != null;
    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 84,
                  child: widget.game.displayCoverUrl == null
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        )
                      : SmoothImage(url: widget.game.displayCoverUrl!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.game.firstReleaseDate != null)
                      Text(
                        formatLongDate(
                              widget.game.firstReleaseDate,
                              L10nScope.of(context).language,
                            ) ??
                            widget.game.firstReleaseDate!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onToggleFavorite != null)
                IconButton(
                  onPressed: widget.favoriteBusy
                      ? null
                      : widget.onToggleFavorite,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    size: 20,
                    color: widget.isFavorited
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SheetSectionCard(
            title: context.t('common:progress'),
            icon: HugeIcons.strokeRoundedStar,
            child: Column(
              children: [
                SheetField(
                  label: context.t('common:status'),
                  child: DropdownMenu<String>(
                    initialSelection: _status.isEmpty ? null : _status,
                    expandedInsets: EdgeInsets.zero,
                    hintText: context.t('feed:selectStatus'),
                    onSelected: (v) => setState(() => _status = v ?? _status),
                    dropdownMenuEntries: [
                      for (final status in statuses)
                        DropdownMenuEntry(
                          value: status,
                          label: context.t('feed:lists.$status'),
                        ),
                    ],
                  ),
                ),
                if (_status == 'played' || _status == 'replaying')
                  SheetField(
                    label: context.t('feed:completionStatus.label'),
                    child: DropdownMenu<String>(
                      initialSelection: _completion.isEmpty
                          ? null
                          : _completion,
                      expandedInsets: EdgeInsets.zero,
                      hintText: context.t('feed:completionStatus.select'),
                      onSelected: (v) => setState(() => _completion = v ?? ''),
                      dropdownMenuEntries: [
                        for (final option in _completionOptions)
                          DropdownMenuEntry(
                            value: option,
                            label: option == '100%'
                                ? '100%'
                                : context.t('feed:completionStatus.$option'),
                          ),
                      ],
                    ),
                  ),
                if (_platformOptions.isNotEmpty)
                  SheetField(
                    label: context.t('library:platforms'),
                    child: OutlinedButton(
                      onPressed: _pickPlatforms,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        alignment: Alignment.centerLeft,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _platforms.isEmpty
                                ? Text(
                                    context.t('feed:selectPlatforms'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final name in _platforms)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            name,
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 6),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                SheetField(
                  label: context.t('feed:hoursPlayed'),
                  child: TextField(
                    textInputAction: TextInputAction.next,
                    controller: _hoursPlayed,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                  ),
                ),
                SheetField(
                  label: context.t('feed:totalReplays'),
                  child: TextField(
                    textInputAction: TextInputAction.next,
                    controller: _playCount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SheetSectionCard(
            title: context.t('feed:timeline'),
            icon: HugeIcons.strokeRoundedCalendar01,
            child: Column(
              children: [
                SheetField(
                  label: context.t('feed:startDate'),
                  child: SheetDateButton(
                    label: _startDate,
                    placeholder: context.t('feed:pickADate'),
                    onTap: () => _pickDate(true),
                  ),
                ),
                SheetField(
                  label: context.t('feed:finishDate'),
                  child: SheetDateButton(
                    label: _finishDate,
                    placeholder: context.t('feed:pickADate'),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GameScreenshotsEditor(
            games: widget.gameService,
            gameId: widget.game.id,
            userId: widget.userId,
          ),
          const SizedBox(height: 16),
          SheetSectionCard(
            title: context.t('feed:notes'),
            icon: HugeIcons.strokeRoundedPencilEdit01,
            child: TextField(
              controller: _progressNotes,
              maxLength: _progressNotesMax,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: context.t('feed:notesPlaceholder'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SheetListSection(
            lists: widget.lists,
            userId: widget.userId,
            type: MediaType.game,
            mediaId: widget.game.id,
            userLists: widget.userLists,
            listStatus: widget.listStatus,
            onChanged: widget.onChanged,
          ),
          if (showReview) ...[
            const SizedBox(height: 16),
            SheetSectionCard(
              title: context.t('feed:review'),
              icon: HugeIcons.strokeRoundedPencilEdit01,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetField(
                    label: context.t('feed:overall'),
                    child: Row(
                      children: [
                        StarRatingInput(
                          value: _overall,
                          size: 26,
                          onChanged: (v) => setState(() {
                            _overall = v;
                            _recommended = v > _recommendedThreshold;
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _overall.toStringAsFixed(1),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  for (final criterion
                      in reviewContent[MediaType.game]!.criteria)
                    SheetField(
                      label: context.t(
                        'feed:criteries.${reviewContent[MediaType.game]!.criteriaLabels[criterion]}',
                      ),
                      child: StarRatingInput(
                        value: _criteria[criterion] ?? 0,
                        size: 20,
                        onChanged: (v) =>
                            setState(() => _criteria[criterion] = v),
                      ),
                    ),
                  SheetField(
                    label: context.t('feed:summary'),
                    child: TextField(
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      controller: _summary,
                      maxLength: _summaryMax,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: context.t('feed:summaryPlaceholder'),
                        counterText: '',
                      ),
                    ),
                  ),
                  SheetField(
                    label: context.t('feed:notes'),
                    child: TextField(
                      controller: _reviewNotes,
                      maxLength: _reviewNotesMax,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: context.t('feed:notesPlaceholder'),
                        counterText: '',
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(context.t('feed:recommended')),
                    value: _recommended,
                    onChanged: (v) => setState(() => _recommended = v ?? false),
                  ),
                ],
              ),
            ),
          ],
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                context.t('api:INTERNAL_SERVER_ERROR'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (canDelete)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _deleting || _saving ? null : _delete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                    label: Text(context.t('common:delete')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              if (canDelete) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _saving || _deleting ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.t('common:saveChanges')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformPickerDialog extends StatefulWidget {
  const _PlatformPickerDialog({required this.options, required this.selected});

  final List<GamePlatform> options;
  final Set<String> selected;

  @override
  State<_PlatformPickerDialog> createState() => _PlatformPickerDialogState();
}

class _PlatformPickerDialogState extends State<_PlatformPickerDialog> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final p in widget.options)
        if (_query.isEmpty ||
            p.name.toLowerCase().contains(_query.toLowerCase()))
          p,
    ];
    return AlertDialog(
      title: Text(context.t('library:platforms')),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: Column(
          children: [
            TextField(
              textInputAction: TextInputAction.search,
              autofocus: false,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: context.t('common:search'),
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: options.isEmpty
                  ? Center(child: Text(context.t('common:noResults')))
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        for (final p in options)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(p.name),
                            value: _selected.contains(p.name),
                            onChanged: (v) => setState(
                              () => v == true
                                  ? _selected.add(p.name)
                                  : _selected.remove(p.name),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text(context.t('common:save')),
        ),
      ],
    );
  }
}

class GameScreenshotsEditor extends StatefulWidget {
  const GameScreenshotsEditor({
    super.key,
    required this.games,
    required this.gameId,
    required this.userId,
  });

  final GameService games;
  final String gameId;
  final String userId;

  @override
  State<GameScreenshotsEditor> createState() => _GameScreenshotsEditorState();
}

class _GameScreenshotsEditorState extends State<GameScreenshotsEditor> {
  final _items = <GameScreenshot>[];
  final _uploading = <String>{};
  final _videoUrl = TextEditingController();
  final _scroll = ScrollController();
  var _page = 0;
  var _hasNext = false;
  var _loading = false;
  var _loadingMore = false;
  String? _removingId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _load();
  }

  @override
  void dispose() {
    _videoUrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await widget.games.screenshots(
        userId: widget.userId,
        gameId: widget.gameId,
        itemsPerPage: 20,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.inPage;
        _hasNext = page.hasNextPage;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeLoadMore() {
    if (_loading || _loadingMore || !_hasNext) return;
    if (!_scroll.hasClients ||
        _scroll.position.pixels < _scroll.position.maxScrollExtent - 120) {
      return;
    }
    _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await widget.games.screenshots(
        userId: widget.userId,
        gameId: widget.gameId,
        page: _page + 1,
        itemsPerPage: 20,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.inPage;
        _hasNext = page.hasNextPage;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickMultiImage(limit: 5);
    if (picked.isEmpty || !mounted) return;
    for (final file in picked) {
      if (!_screenshotExtensions.hasMatch(file.name)) {
        _toast('feed:screenshotTypeInvalid', {'name': file.name});
        continue;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > _screenshotMaxBytes) {
        _toast('feed:screenshotTooLarge', {'name': file.name});
        continue;
      }
      unawaitedUpload(file.name, bytes);
    }
  }

  void unawaitedUpload(String name, List<int> bytes) {
    final tempId = '$name-${DateTime.now().microsecondsSinceEpoch}';
    setState(() => _uploading.add(tempId));
    () async {
      try {
        final url = await widget.games.uploadImage(
          bytes,
          filename: name,
          language: L10nScope.of(context).language,
        );
        final screenshot = await widget.games.createScreenshot(
          gameId: widget.gameId,
          url: url,
        );
        if (mounted) setState(() => _items.insert(0, screenshot));
      } catch (_) {
        _toast('feed:screenshotUploadFailed');
      } finally {
        if (mounted) setState(() => _uploading.remove(tempId));
      }
    }();
  }

  Future<void> _addVideo() async {
    final input = _videoUrl.text.trim();
    if (input.isEmpty) return;
    final video = parseVideoUrl(input);
    if (video == null) {
      _toast('api:INVALID_VIDEO_URL');
      return;
    }
    try {
      final screenshot = await widget.games.createScreenshot(
        gameId: widget.gameId,
        url: video.url,
        type: 'Video',
      );
      if (mounted) {
        setState(() {
          _items.insert(0, screenshot);
          _videoUrl.clear();
        });
      }
    } catch (_) {
      _toast('feed:videoAddFailed');
    }
  }

  Future<void> _updateDescription(GameScreenshot shot, String value) async {
    if (value == (shot.description ?? '')) return;
    try {
      final updated = await widget.games.updateScreenshot(
        shot.id,
        description: value,
      );
      if (mounted) {
        setState(() {
          final i = _items.indexWhere((s) => s.id == shot.id);
          if (i >= 0) _items[i] = updated;
        });
      }
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    }
  }

  Future<void> _updateSpoiler(GameScreenshot shot, bool value) async {
    try {
      final updated = await widget.games.updateScreenshot(
        shot.id,
        isSpoiler: value,
      );
      if (mounted) {
        setState(() {
          final i = _items.indexWhere((s) => s.id == shot.id);
          if (i >= 0) _items[i] = updated;
        });
      }
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    }
  }

  Future<void> _remove(GameScreenshot shot) async {
    if (_removingId != null) return;
    setState(() => _removingId = shot.id);
    try {
      await widget.games.deleteScreenshot(shot.id);
      if (mounted) setState(() => _items.removeWhere((s) => s.id == shot.id));
    } catch (_) {
      _toast('api:INTERNAL_SERVER_ERROR');
    } finally {
      if (mounted) setState(() => _removingId = null);
    }
  }

  void _toast(String key, [Map<String, Object>? params]) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.t(key, params ?? const {}))));
  }

  @override
  Widget build(BuildContext context) {
    return SheetSectionCard(
      title: context.t('common:screenshots'),
      icon: HugeIcons.strokeRoundedImage01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _pickAndUpload,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUpload01,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              context
                  .t('feed:uploadScreenshot')
                  .replaceAll(RegExp('<[^>]*>'), ''),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  textInputAction: TextInputAction.done,
                  controller: _videoUrl,
                  onSubmitted: (_) => _addVideo(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: context.t('feed:videoUrlPlaceholder'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addVideo,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                tooltip: context.t('feed:addVideo'),
              ),
            ],
          ),
          if (_loading && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_items.isNotEmpty || _uploading.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 260,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  controller: _scroll,
                  children: [
                    for (final tempId in _uploading)
                      _UploadingRow(key: ValueKey(tempId)),
                    for (final shot in _items)
                      _ScreenshotRow(
                        key: ValueKey(shot.id),
                        screenshot: shot,
                        removing: _removingId == shot.id,
                        onDescription: (v) => _updateDescription(shot, v),
                        onSpoiler: (v) => _updateSpoiler(shot, v),
                        onRemove: () => _remove(shot),
                      ),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadingRow extends StatelessWidget {
  const _UploadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            context.t('feed:screenshotUploading'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenshotRow extends StatefulWidget {
  const _ScreenshotRow({
    super.key,
    required this.screenshot,
    required this.removing,
    required this.onDescription,
    required this.onSpoiler,
    required this.onRemove,
  });

  final GameScreenshot screenshot;
  final bool removing;
  final ValueChanged<String> onDescription;
  final ValueChanged<bool> onSpoiler;
  final VoidCallback onRemove;

  @override
  State<_ScreenshotRow> createState() => _ScreenshotRowState();
}

class _ScreenshotRowState extends State<_ScreenshotRow> {
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(
      text: widget.screenshot.description ?? '',
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shot = widget.screenshot;
    final video = shot.type == 'Video' ? parseVideoUrl(shot.url) : null;
    final thumbnail = video != null ? videoThumbnailUrl(video) : shot.url;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail != null && thumbnail.isNotEmpty)
                    SmoothImage(url: thumbnail)
                  else
                    Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: HugeIcon(
                          icon: video != null
                              ? HugeIcons.strokeRoundedPlay
                              : HugeIcons.strokeRoundedImage01,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (video != null)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  textInputAction: TextInputAction.done,
                  controller: _description,
                  maxLength: _screenshotDescriptionMax,
                  onEditingComplete: () =>
                      widget.onDescription(_description.text.trim()),
                  onTapOutside: (_) =>
                      widget.onDescription(_description.text.trim()),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: context.t('feed:screenshotDescription'),
                    counterText: '',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    context.t('feed:spoiler'),
                    style: theme.textTheme.labelMedium,
                  ),
                  value: shot.isSpoiler,
                  onChanged: (v) => widget.onSpoiler(v ?? false),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.removing ? null : widget.onRemove,
            visualDensity: VisualDensity.compact,
            icon: widget.removing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }
}
