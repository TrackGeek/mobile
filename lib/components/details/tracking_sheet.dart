import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/anime_detail.dart';
import '../../models/media_type.dart';
import '../../models/review.dart';
import '../../models/user_list.dart';
import '../../services/anime_service.dart';
import '../../services/list_service.dart';
import '../../services/review_service.dart';
import '../user/star_rating.dart';

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
const _notesMax = 10000;

class TrackingSheet extends StatefulWidget {
  const TrackingSheet({
    super.key,
    required this.anime,
    required this.animeService,
    required this.reviews,
    required this.lists,
    required this.userId,
    required this.unreleased,
    required this.progress,
    required this.ownReview,
    required this.episodeWatch,
    required this.userLists,
    required this.listStatus,
    this.isFavorited = false,
    this.favoriteBusy = false,
    this.onToggleFavorite,
    this.onChanged,
  });

  final AnimeDetail anime;
  final AnimeService animeService;
  final ReviewService reviews;
  final ListService lists;
  final String userId;
  final bool unreleased;
  final AnimeProgress? progress;
  final UserReview? ownReview;
  final List<AnimeEpisodeWatch> episodeWatch;
  final List<UserList> userLists;
  final List<String> listStatus;
  final bool isFavorited;
  final bool favoriteBusy;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onChanged;

  static Future<void> open(
    BuildContext context, {
    required AnimeDetail anime,
    required AnimeService animeService,
    required ReviewService reviews,
    required ListService lists,
    required String userId,
    required bool unreleased,
    required AnimeProgress? progress,
    required UserReview? ownReview,
    required List<AnimeEpisodeWatch> episodeWatch,
    required List<UserList> userLists,
    required List<String> listStatus,
    bool isFavorited = false,
    bool favoriteBusy = false,
    VoidCallback? onToggleFavorite,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: TrackingSheet(
          anime: anime,
          animeService: animeService,
          reviews: reviews,
          lists: lists,
          userId: userId,
          unreleased: unreleased,
          progress: progress,
          ownReview: ownReview,
          episodeWatch: episodeWatch,
          userLists: userLists,
          listStatus: listStatus,
          isFavorited: isFavorited,
          favoriteBusy: favoriteBusy,
          onToggleFavorite: onToggleFavorite,
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  State<TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends State<TrackingSheet> {
  late String _status;
  late final TextEditingController _episodes;
  late final TextEditingController _watchCount;
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

  int get _watchedCount => widget.episodeWatch
      .where((w) => w.status == 'Completed')
      .map((w) => w.episode)
      .toSet()
      .length;

  int get _totalEpisodes => widget.anime.numberOfEpisodes ?? 0;

  @override
  void initState() {
    super.initState();
    final progress = widget.progress;
    _status = _enumToStatus[progress?.status] ?? '';
    _episodes = TextEditingController(text: '$_watchedCount');
    _watchCount = TextEditingController(
      text: progress?.watchCount?.toString() ?? '',
    );
    _startDate = DateTime.tryParse(progress?.startedAt ?? '');
    _finishDate = DateTime.tryParse(progress?.completedAt ?? '');
    final review = widget.ownReview;
    _overall = review?.overall ?? 0;
    _criteria = {
      for (final key in reviewContent[MediaType.anime]!.criteria)
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
    _summary.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _commitEpisodes() async {
    if (_busyEpisodes || _totalEpisodes <= 0) return;
    final parsed = int.tryParse(_episodes.text) ?? 0;
    final target = parsed.clamp(0, _totalEpisodes);
    if ('$target' != _episodes.text) {
      _episodes.text = '$target';
      _episodes.selection = TextSelection.collapsed(
        offset: _episodes.text.length,
      );
    }
    final watched = widget.episodeWatch
        .where((w) => w.status == 'Completed')
        .map((w) => w.episode)
        .toSet();
    if (target == watched.length) return;
    setState(() => _busyEpisodes = true);
    try {
      final toAdd = [
        for (var e = 1; e <= target; e++)
          if (!watched.contains(e)) e,
      ];
      final toRemove = [
        for (var e = target + 1; e <= _totalEpisodes; e++)
          if (watched.contains(e)) e,
      ];
      if (toAdd.isNotEmpty) {
        await widget.animeService.watchEpisodes(widget.anime.id, toAdd);
      }
      for (final episode in toRemove) {
        await widget.animeService.unwatchEpisode(widget.anime.id, episode);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _startDate : _finishDate) ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 10),
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
      await widget.animeService.saveProgress(
        widget.anime.id,
        status: statusEnum,
        watchCount: int.tryParse(_watchCount.text),
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
            MediaType.anime,
            mediaId: widget.anime.id,
            fields: fields,
          );
        }
      }
      widget.onChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
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
      await widget.animeService.unwatchAll(widget.anime.id);
      final progress = widget.progress;
      if (progress != null) {
        await widget.animeService.deleteProgress(progress.id);
      }
      final review = widget.ownReview;
      if (review != null) await widget.reviews.deleteReview(review);
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
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
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
                    child: widget.anime.imageUrl == null
                        ? Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          )
                        : Image.network(
                            widget.anime.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.anime.season != null &&
                          widget.anime.year != null)
                        Text(
                          '${widget.anime.season} ${widget.anime.year}',
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
                      icon: widget.isFavorited
                          ? HugeIcons.strokeRoundedFavourite
                          : HugeIcons.strokeRoundedFavourite,
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
                  if (!widget.unreleased) ...[
                    SheetField(
                      label: context.t('library:episode_other'),
                      child: TextField(
                        controller: _episodes,
                        enabled: _totalEpisodes > 0 && !_busyEpisodes,
                        keyboardType: TextInputType.number,
                        onEditingComplete: _commitEpisodes,
                        onSubmitted: (_) => _commitEpisodes(),
                        onTapOutside: (_) => _commitEpisodes(),
                        decoration: InputDecoration(
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixText: '/$_totalEpisodes',
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
                        controller: _watchCount,
                        keyboardType: TextInputType.number,
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SheetListSection(
              lists: widget.lists,
              userId: widget.userId,
              type: MediaType.anime,
              mediaId: widget.anime.id,
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
                        in reviewContent[MediaType.anime]!.criteria)
                      SheetField(
                        label: context.t(
                          'feed:criteries.${reviewContent[MediaType.anime]!.criteriaLabels[criterion]}',
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
                      onChanged: (v) =>
                          setState(() => _recommended = v ?? false),
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
                if (widget.progress != null)
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
                if (widget.progress != null) const SizedBox(width: 10),
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
      ),
    );
  }
}

class SheetSectionCard extends StatelessWidget {
  const SheetSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final List<List<dynamic>> icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SheetField extends StatelessWidget {
  const SheetField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class SheetDateButton extends StatelessWidget {
  const SheetDateButton({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
  });

  final DateTime? label;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = label;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 15),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value == null
              ? placeholder
              : MaterialLocalizations.of(context).formatMediumDate(value),
          style: theme.textTheme.bodySmall?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

class SheetListSection extends StatefulWidget {
  const SheetListSection({
    super.key,
    required this.lists,
    required this.userId,
    required this.type,
    required this.mediaId,
    required this.userLists,
    required this.listStatus,
    this.onChanged,
  });

  final ListService lists;
  final String userId;
  final MediaType type;
  final String mediaId;
  final List<UserList> userLists;
  final List<String> listStatus;
  final VoidCallback? onChanged;

  @override
  State<SheetListSection> createState() => _SheetListSectionState();
}

class _SheetListSectionState extends State<SheetListSection> {
  late Set<String> _listIds;
  late List<UserList> _userLists;
  final _newList = TextEditingController();
  String? _listError;

  @override
  void initState() {
    super.initState();
    _listIds = widget.listStatus.toSet();
    _userLists = [...widget.userLists];
  }

  @override
  void dispose() {
    _newList.dispose();
    super.dispose();
  }

  Future<void> _toggleList(UserList list, bool isMember) async {
    try {
      await widget.lists.toggleListItem(
        list.id,
        type: widget.type,
        mediaId: widget.mediaId,
        userId: widget.userId,
        isMember: isMember,
      );
      setState(
        () => isMember ? _listIds.remove(list.id) : _listIds.add(list.id),
      );
      widget.onChanged?.call();
    } catch (_) {
      setState(() => _listError = 'api:INTERNAL_SERVER_ERROR');
    }
  }

  Future<void> _createList() async {
    final name = _newList.text.trim();
    if (name.isEmpty) return;
    final language = L10nScope.of(context).language;
    try {
      await widget.lists.createList(
        widget.userId,
        name: name,
        type: widget.type,
      );
      final fresh = await widget.lists.userLists(
        widget.userId,
        type: widget.type,
        itemsPerPage: 50,
        language: language,
      );
      final created = fresh.items.reversed.cast<UserList?>().firstWhere(
        (l) => l!.name == name,
        orElse: () => null,
      );
      if (created != null) {
        await widget.lists.toggleListItem(
          created.id,
          type: widget.type,
          mediaId: widget.mediaId,
          userId: widget.userId,
          isMember: false,
        );
      }
      if (!mounted) return;
      setState(() {
        _userLists = fresh.items;
        if (created != null) _listIds.add(created.id);
        _newList.clear();
      });
      widget.onChanged?.call();
    } catch (_) {
      setState(() => _listError = 'api:INTERNAL_SERVER_ERROR');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SheetSectionCard(
      title: context.t('common:lists'),
      icon: HugeIcons.strokeRoundedListView,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newList,
                  onSubmitted: (_) => _createList(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: context.t('feed:newList'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _createList,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 16,
                ),
              ),
            ],
          ),
          if (_listError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.t(_listError!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_userLists.isEmpty)
            Text(
              context.t('library:noLists'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final list in _userLists)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: _listIds.contains(list.id),
                onChanged: (_) => _toggleList(list, _listIds.contains(list.id)),
              ),
        ],
      ),
    );
  }
}
