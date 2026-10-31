import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/review.dart';
import '../../models/tv_detail.dart';
import '../../models/user_list.dart';
import '../../services/list_service.dart';
import '../../services/review_service.dart';
import '../../services/tv_show_service.dart';
import '../user/star_rating.dart';
import '../layout/bottom_padding.dart';
import 'tracking_sheet.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';
import '../../utils/adaptive_sheet_route.dart';

const _statusOptions = [
  'planning',
  'watching',
  'completed',
  'rewatching',
  'dropped',
  'paused',
];

const _statusToEnum = {
  'planning': 'Planning',
  'watching': 'Watching',
  'completed': 'Completed',
  'rewatching': 'Rewatching',
  'dropped': 'Dropped',
  'paused': 'Paused',
};

const _enumToStatus = {
  'Planning': 'planning',
  'Watching': 'watching',
  'Rewatching': 'rewatching',
  'Completed': 'completed',
  'Paused': 'paused',
  'Dropped': 'dropped',
};

const _reviewStatuses = {'completed', 'dropped', 'rewatching'};
const _recommendedThreshold = 2.5;
const _summaryMax = 500;
const _progressNotesMax = 1000;
const _notesMax = 10000;

class TvTrackingSheet extends StatefulWidget {
  const TvTrackingSheet({
    super.key,
    required this.tvShow,
    required this.tvShowService,
    required this.reviews,
    required this.lists,
    required this.userId,
    required this.unreleased,
    required this.progress,
    required this.ownReview,
    required this.episodeWatch,
    required this.seasons,
    required this.userLists,
    required this.listStatus,
    this.isFavorited = false,
    this.favoriteBusy = false,
    this.onToggleFavorite,
    this.onChanged,
  });

  final TvShowDetail tvShow;
  final TvShowService tvShowService;
  final ReviewService reviews;
  final ListService lists;
  final String userId;
  final bool unreleased;
  final TvShowProgress? progress;
  final UserReview? ownReview;
  final List<TvEpisodeWatch> episodeWatch;
  final List<TvSeason> seasons;
  final List<UserList> userLists;
  final List<String> listStatus;
  final bool isFavorited;
  final bool favoriteBusy;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onChanged;

  static Future<void> open(
    BuildContext context, {
    required TvShowDetail tvShow,
    required TvShowService tvShowService,
    required ReviewService reviews,
    required ListService lists,
    required String userId,
    required bool unreleased,
    required TvShowProgress? progress,
    required UserReview? ownReview,
    required List<TvEpisodeWatch> episodeWatch,
    required List<TvSeason> seasons,
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
        child: TvTrackingSheet(
          tvShow: tvShow,
          tvShowService: tvShowService,
          reviews: reviews,
          lists: lists,
          userId: userId,
          unreleased: unreleased,
          progress: progress,
          ownReview: ownReview,
          episodeWatch: episodeWatch,
          seasons: seasons,
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
  State<TvTrackingSheet> createState() => _TvTrackingSheetState();
}

class _TvTrackingSheetState extends State<TvTrackingSheet> {
  late String _status;
  late final TextEditingController _episodes;
  late final TextEditingController _watchCount;
  late final TextEditingController _progressNotes;
  late final TextEditingController _summary;
  late final TextEditingController _notes;
  late double _overall;
  late final Map<String, double> _criteria;
  late bool _recommended;
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _saving = false;
  bool _deleting = false;
  bool _busyEpisodes = false;
  bool _error = false;

  List<({int season, int episode})> get _orderedEpisodes {
    final ordered = [
      for (final s in widget.seasons)
        if (s.numberOfEpisodes > 0 && s.seasonNumber > 0) s,
    ]..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return [
      for (final s in ordered)
        for (var e = 1; e <= s.numberOfEpisodes; e++)
          (season: s.seasonNumber, episode: e),
    ];
  }

  Set<String> get _watchedSet => {
    for (final w in widget.episodeWatch)
      if (w.status == 'Completed') '${w.season}-${w.episode}',
  };

  int get _watchedCount => _watchedSet.length;

  @override
  void initState() {
    super.initState();
    final progress = widget.progress;
    _status = _enumToStatus[progress?.status] ?? '';
    _episodes = TextEditingController(text: '$_watchedCount');
    _watchCount = TextEditingController(
      text: progress?.watchCount?.toString() ?? '',
    );
    _progressNotes = TextEditingController(text: progress?.notes ?? '');
    _startDate = DateTime.tryParse(progress?.startedAt ?? '');
    _finishDate = DateTime.tryParse(progress?.completedAt ?? '');
    final review = widget.ownReview;
    _overall = review?.overall ?? 0;
    _criteria = {
      for (final key in reviewContent[MediaType.tv]!.criteria)
        key: review?.fields[key] ?? 0,
    };
    _summary = TextEditingController(text: review?.summary ?? '');
    _notes = TextEditingController(text: review?.notes ?? '');
    _recommended = review?.recommended ?? false;
  }

  @override
  void dispose() {
    _episodes.dispose();
    _watchCount.dispose();
    _progressNotes.dispose();
    _summary.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _commitEpisodes() async {
    final ordered = _orderedEpisodes;
    if (_busyEpisodes || ordered.isEmpty) return;
    final parsed = int.tryParse(_episodes.text) ?? 0;
    final target = parsed.clamp(0, ordered.length);
    if ('$target' != _episodes.text) {
      _episodes.text = '$target';
      _episodes.selection = TextSelection.collapsed(
        offset: _episodes.text.length,
      );
    }
    final watched = _watchedSet;
    if (target == watched.length) return;
    setState(() => _busyEpisodes = true);
    try {
      final toAdd = [
        for (final e in ordered.take(target))
          if (!watched.contains('${e.season}-${e.episode}')) e,
      ];
      final toRemove = [
        for (final e in ordered.skip(target))
          if (watched.contains('${e.season}-${e.episode}')) e,
      ];
      if (toAdd.isNotEmpty) {
        await widget.tvShowService.watchEpisodes(widget.tvShow.id, toAdd);
      }
      for (final e in toRemove) {
        await widget.tvShowService.unwatchEpisode(
          widget.tvShow.id,
          e.season,
          e.episode,
        );
      }
      widget.onChanged?.call();
    } catch (_) {
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busyEpisodes = false);
    }
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final release = DateTime.tryParse(widget.tvShow.firstAirDate ?? '');
    final minStart = release == null
        ? null
        : DateTime(release.year, release.month, release.day);
    final firstDate =
        (start
            ? minStart
            : [minStart, _startDate].whereType<DateTime>().fold<DateTime?>(
                null,
                (a, b) => a == null || b.isAfter(a) ? b : a,
              )) ??
        DateTime(1950);
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
      await widget.tvShowService.saveProgress(
        widget.tvShow.id,
        status: statusEnum,
        watchCount: int.tryParse(_watchCount.text)?.clamp(0, 999),
        startedAt: _startDate?.toIso8601String(),
        completedAt: statusEnum == 'Completed'
            ? (_finishDate ?? DateTime.now()).toIso8601String()
            : _finishDate?.toIso8601String(),
        notes: _progressNotes.text.trim().isEmpty
            ? null
            : _progressNotes.text.trim(),
      );
      if (_reviewStatuses.contains(_status) && _overall > 0) {
        final story = widget.ownReview?.story?.trim();
        final fields = <String, Object?>{
          'overall': _overall,
          if (_summary.text.trim().isNotEmpty) 'summary': _summary.text.trim(),
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
          'recommended': _recommended,
          if (story != null && story.isNotEmpty) 'story': story,
          for (final entry in _criteria.entries)
            if (entry.value > 0) entry.key: entry.value,
        };
        final existing = widget.ownReview;
        if (existing != null) {
          await widget.reviews.updateReview(existing, fields: fields);
        } else {
          await widget.reviews.createReview(
            MediaType.tv,
            mediaId: widget.tvShow.id,
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
      await widget.tvShowService.resetTracking(widget.tvShow.id);
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
    final showReview = _reviewStatuses.contains(_status);
    final firstYear = DateTime.tryParse(widget.tvShow.firstAirDate ?? '')?.year;
    final lastYear = DateTime.tryParse(widget.tvShow.lastAirDate ?? '')?.year;
    final canDelete = widget.progress != null || widget.ownReview != null;
    final totalOrdered = _orderedEpisodes.length;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        BottomPadding.of(context, minimum: 24),
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 84,
                child: widget.tvShow.posterUrl == null
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      )
                    : SmoothImage(url: widget.tvShow.posterUrl!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tvShow.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (firstYear != null)
                    Text(
                      '$firstYear${lastYear != null && lastYear != firstYear ? ' - $lastYear' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.onToggleFavorite != null)
              IconButton(
                onPressed: widget.favoriteBusy ? null : widget.onToggleFavorite,
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
        const SizedBox(height: 20),
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
              if (!widget.unreleased) ...[
                SheetField(
                  label: context.t('library:episode_other'),
                  child: TextField(
                    textInputAction: TextInputAction.done,
                    controller: _episodes,
                    enabled: totalOrdered > 0 && !_busyEpisodes,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onEditingComplete: _commitEpisodes,
                    onSubmitted: (_) => _commitEpisodes(),
                    onTapOutside: (_) => _commitEpisodes(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixText:
                          '/${widget.tvShow.numberOfEpisodes ?? totalOrdered}',
                      suffixIcon: _busyEpisodes
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                SheetField(
                  label: context.t('feed:totalRewatches'),
                  child: TextField(
                    textInputAction: TextInputAction.next,
                    controller: _watchCount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
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
                SheetField(
                  label: context.t('feed:notes'),
                  child: TextField(
                    controller: _progressNotes,
                    maxLength: _progressNotesMax,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: context.t('feed:notesPlaceholder'),
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SheetListSection(
          lists: widget.lists,
          userId: widget.userId,
          type: MediaType.tv,
          mediaId: widget.tvShow.id,
          userLists: widget.userLists,
          listStatus: widget.listStatus,
          onChanged: widget.onChanged,
        ),
        if (showReview && !widget.unreleased) ...[
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
                for (final criterion in reviewContent[MediaType.tv]!.criteria)
                  SheetField(
                    label: context.t(
                      'feed:criteries.${reviewContent[MediaType.tv]!.criteriaLabels[criterion]}',
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
                    controller: _notes,
                    maxLength: _notesMax,
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
                    : Text(context.t('common:save')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
