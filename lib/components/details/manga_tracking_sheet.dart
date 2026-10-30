import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/manga_detail.dart';
import '../../models/media_type.dart';
import '../../models/review.dart';
import '../../models/user_list.dart';
import '../../services/list_service.dart';
import '../../services/manga_service.dart';
import '../../services/review_service.dart';
import '../user/star_rating.dart';
import 'tracking_sheet.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';
import '../../utils/adaptive_sheet_route.dart';

const _statusOptions = [
  'planning',
  'reading',
  'completed',
  'rereading',
  'dropped',
  'paused',
];

const _statusToEnum = {
  'planning': 'Planning',
  'reading': 'Reading',
  'completed': 'Completed',
  'rereading': 'Rereading',
  'dropped': 'Dropped',
  'paused': 'Paused',
};

const _enumToStatus = {
  'Planning': 'planning',
  'Reading': 'reading',
  'Rereading': 'rereading',
  'Completed': 'completed',
  'Paused': 'paused',
  'Dropped': 'dropped',
};

const _reviewStatuses = {'completed', 'dropped', 'rereading'};
const _recommendedThreshold = 2.5;
const _summaryMax = 500;
const _notesMax = 10000;

class MangaTrackingSheet extends StatefulWidget {
  const MangaTrackingSheet({
    super.key,
    required this.manga,
    required this.mangaService,
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

  final MangaDetail manga;
  final MangaService mangaService;
  final ReviewService reviews;
  final ListService lists;
  final String userId;
  final bool unreleased;
  final MangaProgress? progress;
  final UserReview? ownReview;
  final List<UserList> userLists;
  final List<String> listStatus;
  final bool isFavorited;
  final bool favoriteBusy;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onChanged;

  static Future<void> open(
    BuildContext context, {
    required MangaDetail manga,
    required MangaService mangaService,
    required ReviewService reviews,
    required ListService lists,
    required String userId,
    required bool unreleased,
    required MangaProgress? progress,
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
        child: MangaTrackingSheet(
          manga: manga,
          mangaService: mangaService,
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
  State<MangaTrackingSheet> createState() => _MangaTrackingSheetState();
}

class _MangaTrackingSheetState extends State<MangaTrackingSheet> {
  late String _status;
  late final TextEditingController _chaptersRead;
  late final TextEditingController _readCount;
  late final TextEditingController _summary;
  late final TextEditingController _notes;
  late double _overall;
  late final Map<String, double> _criteria;
  late bool _recommended;
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _saving = false;
  bool _deleting = false;
  bool _error = false;

  int? get _totalChapters {
    final value = widget.manga.numberOfChapters;
    return value != null && value > 0 ? value : null;
  }

  DateTime? get _minStartDate {
    final parsed = DateTime.tryParse(widget.manga.published?.from ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  @override
  void initState() {
    super.initState();
    final progress = widget.progress;
    _status = _enumToStatus[progress?.status] ?? '';
    _chaptersRead = TextEditingController(
      text: progress?.chaptersRead?.toString() ?? '',
    );
    _readCount = TextEditingController(
      text: progress?.readCount?.toString() ?? '',
    );
    _startDate = DateTime.tryParse(progress?.startedAt ?? '');
    _finishDate = DateTime.tryParse(progress?.completedAt ?? '');
    final review = widget.ownReview;
    _overall = review?.overall ?? 0;
    _criteria = {
      for (final key in reviewContent[MediaType.manga]!.criteria)
        key: review?.fields[key] ?? 0,
    };
    _summary = TextEditingController(text: review?.summary ?? '');
    _notes = TextEditingController(text: review?.notes ?? '');
    _recommended = review?.recommended ?? false;
  }

  @override
  void dispose() {
    _chaptersRead.dispose();
    _readCount.dispose();
    _summary.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onStatusChanged(String? status) {
    if (status == null) return;
    setState(() {
      _status = status;
      final total = _totalChapters;
      if (status == 'completed' && total != null) {
        _chaptersRead.text = '$total';
      }
    });
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

  int? _parseCount(TextEditingController controller) {
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) return null;
    return parsed;
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
      await widget.mangaService.saveProgress(
        widget.manga.id,
        status: statusEnum,
        chaptersRead: _parseCount(_chaptersRead),
        readCount: _parseCount(_readCount),
        startedAt: _startDate?.toIso8601String(),
        completedAt: statusEnum == 'Completed'
            ? (_finishDate ?? DateTime.now()).toIso8601String()
            : _finishDate?.toIso8601String(),
      );
      if (_reviewStatuses.contains(_status) && _overall > 0) {
        final fields = <String, Object?>{
          'overall': _overall,
          if (_summary.text.trim().isNotEmpty) 'summary': _summary.text.trim(),
          if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
          'recommended': _recommended,
          for (final entry in _criteria.entries)
            if (entry.value > 0) entry.key: entry.value,
        };
        final existing = widget.ownReview;
        if (existing != null) {
          await widget.reviews.updateReview(existing, fields: fields);
        } else {
          await widget.reviews.createReview(
            MediaType.manga,
            mediaId: widget.manga.id,
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
      final review = widget.ownReview;
      if (review != null) await widget.reviews.deleteReview(review);
      final progress = widget.progress;
      if (progress != null) {
        await widget.mangaService.deleteProgress(progress.id);
      }
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
    final canDelete = widget.progress != null || widget.ownReview != null;
    final total = _totalChapters;
    return SafeArea(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 84,
                  child: widget.manga.imageUrl == null
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        )
                      : SmoothImage(url: widget.manga.imageUrl!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.manga.published?.string != null)
                      Text(
                        widget.manga.published!.string!,
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
                    onSelected: _onStatusChanged,
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
                    label: context.t('library:chapters'),
                    child: TextField(
                      controller: _chaptersRead,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        hintText: '0',
                        suffixText: total == null ? null : '/$total',
                      ),
                    ),
                  ),
                  SheetField(
                    label: context.t('feed:totalRereads'),
                    child: TextField(
                      controller: _readCount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: '0',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.unreleased) ...[
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
          ],
          const SizedBox(height: 16),
          SheetListSection(
            lists: widget.lists,
            userId: widget.userId,
            type: MediaType.manga,
            mediaId: widget.manga.id,
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
                  for (final criterion
                      in reviewContent[MediaType.manga]!.criteria)
                    SheetField(
                      label: context.t(
                        'feed:criteries.${reviewContent[MediaType.manga]!.criteriaLabels[criterion]}',
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
      ),
    );
  }
}
