import 'dart:ui';

import 'package:flutter/material.dart';

import '../layout/adaptive_grid_delegate.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/company.dart';
import '../media/smooth_image.dart';
import '../layout/bottom_padding.dart';
import '../../models/media_type.dart';
import '../../utils/haptics.dart';
import '../../utils/numbers.dart';

const _pageSize = 24;

enum _Sort { newest, oldest, topRated }

class CompanyWorksSection extends StatefulWidget {
  const CompanyWorksSection({
    super.key,
    required this.works,
    required this.onOpenWork,
  });

  final List<CompanyWork> works;
  final void Function(CompanyWork work) onOpenWork;

  @override
  State<CompanyWorksSection> createState() => _CompanyWorksSectionState();
}

class _CompanyWorksSectionState extends State<CompanyWorksSection> {
  String _query = '';
  MediaType? _media;
  String? _role;
  _Sort _sort = _Sort.newest;
  var _visible = _pageSize;

  int get _activeFilters =>
      (_media != null ? 1 : 0) +
      (_role != null ? 1 : 0) +
      (_sort != _Sort.newest ? 1 : 0);

  List<CompanyWork> get _filtered {
    var items = widget.works.where((w) {
      if (_media != null && w.mediaType != _media) return false;
      if (_role != null && !w.roles.contains(_role)) return false;
      return true;
    }).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = [
        for (final w in items)
          if (w.title.toLowerCase().contains(q)) w,
      ];
    }
    items.sort((a, b) {
      return switch (_sort) {
        _Sort.newest => _dateValue(b).compareTo(_dateValue(a)),
        _Sort.oldest => _dateValue(a).compareTo(_dateValue(b)),
        _Sort.topRated => (b.externalReviewScore ?? b.tgReviewScore).compareTo(
          a.externalReviewScore ?? a.tgReviewScore,
        ),
      };
    });
    return items;
  }

  int _dateValue(CompanyWork work) {
    final date = DateTime.tryParse(work.releaseDate ?? '');
    if (date != null) return date.millisecondsSinceEpoch;
    return (work.year ?? 0) * 365 * 24 * 3600 * 1000;
  }

  Map<String, int> get _roleCounts {
    final counts = <String, int>{};
    for (final work in widget.works) {
      for (final role in work.roles) {
        counts[role] = (counts[role] ?? 0) + 1;
      }
    }
    return counts;
  }

  void _openFilters({
    required List<({MediaType? value, String label, int count})> media,
    required List<MapEntry<String, int>> roles,
    required List<({_Sort value, String label, List<List<dynamic>> icon})>
    sortOptions,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticsHelper.light();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final theme = Theme.of(sheetContext);
          void update(VoidCallback fn) {
            HapticsHelper.selection();
            setState(() {
              fn();
              _visible = _pageSize;
            });
            setSheet(() {});
          }

          Widget section(String title, Widget child) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          );

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: BottomPadding.of(sheetContext, minimum: 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.t('library:filters'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_activeFilters > 0)
                        TextButton(
                          onPressed: () => update(() {
                            _media = null;
                            _role = null;
                            _sort = _Sort.newest;
                          }),
                          child: Text(context.t('library:resetFilters')),
                        ),
                    ],
                  ),
                ),
                if (media.where((m) => m.value != null).length > 1)
                  section(
                    context.t('library:mediaType'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in media)
                          ChoiceChip(
                            selected: _media == m.value,
                            onSelected: (_) => update(() => _media = m.value),
                            label: Text('${m.label} · ${m.count}'),
                          ),
                      ],
                    ),
                  ),
                if (roles.length > 1)
                  section(
                    context.t('library:role'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          selected: _role == null,
                          onSelected: (_) => update(() => _role = null),
                          label: Text(context.t('common:all')),
                        ),
                        for (final role in roles)
                          ChoiceChip(
                            selected: _role == role.key,
                            onSelected: (_) => update(() => _role = role.key),
                            label: Text(
                              '${role.key} · ${role.value.humanizedCount()}',
                            ),
                          ),
                      ],
                    ),
                  ),
                section(
                  context.t('library:sortBy'),
                  Column(
                    children: [
                      for (final option in sortOptions)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: HugeIcon(icon: option.icon, size: 20),
                          title: Text(option.label),
                          trailing: _sort == option.value
                              ? HugeIcon(
                                  icon: HugeIcons.strokeRoundedTick02,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => update(() => _sort = option.value),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = _roleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final filtered = _filtered;
    final shown = filtered.take(_visible).toList();
    final activeFilters = _activeFilters;
    int countOf(MediaType t) =>
        widget.works.where((w) => w.mediaType == t).length;
    final media = <({MediaType? value, String label, int count})>[
      (value: null, label: context.t('common:all'), count: widget.works.length),
      for (final t in [
        MediaType.movie,
        MediaType.tv,
        MediaType.anime,
        MediaType.game,
      ])
        if (countOf(t) > 0)
          (
            value: t,
            label: context.t('common:types.${t.name}', {'count': 2}),
            count: countOf(t),
          ),
    ];
    final sortOptions =
        <({_Sort value, String label, List<List<dynamic>> icon})>[
          (
            value: _Sort.newest,
            label: context.t('library:newestFirst'),
            icon: HugeIcons.strokeRoundedArrowDownWideNarrow,
          ),
          (
            value: _Sort.oldest,
            label: context.t('library:oldestFirst'),
            icon: HugeIcons.strokeRoundedArrowUpWideNarrow,
          ),
          (
            value: _Sort.topRated,
            label: context.t('library:topRated'),
            icon: HugeIcons.strokeRoundedStar,
          ),
        ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${context.t('library:catalog')} (${filtered.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() {
                    _query = v.trim();
                    _visible = _pageSize;
                  }),
                  decoration: InputDecoration(
                    hintText: context.t('library:searchTitles'),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 18,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: activeFilters > 0,
                label: Text('$activeFilters'),
                child: IconButton.filledTonal(
                  tooltip: context.t('library:filters'),
                  onPressed: () => _openFilters(
                    media: media,
                    roles: roles,
                    sortOptions: sortOptions,
                  ),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFilterHorizontal,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: Text(
                context.t('library:noTitlesFound'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: AdaptiveGridDelegate(
              context: context,
              maxCrossAxisExtent: 140,
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemCount: shown.length,
            itemBuilder: (context, index) =>
                WorkCard(work: shown[index], onTap: widget.onOpenWork),
          ),
          if (_visible < filtered.length)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _visible += _pageSize),
                  child: Text(context.t('common:showMore')),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class WorkCard extends StatelessWidget {
  const WorkCard({super.key, required this.work, required this.onTap});

  final CompanyWork work;
  final void Function(CompanyWork work) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(work),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _cover(context),
                  if (work.isAdult)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedViewOff,
                            size: 22,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  if (work.isTracked)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            work.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [if (work.year != null) '${work.year}', ...work.roles].join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cover(BuildContext context) {
    final theme = Theme.of(context);
    final url = work.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedImage01,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return SmoothImage(url: url);
  }
}
