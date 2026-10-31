import 'dart:ui';

import 'package:flutter/material.dart';

import '../layout/adaptive_grid_delegate.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/company.dart';
import '../media/smooth_image.dart';
import '../layout/edgy.dart';
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
  final _search = TextEditingController();
  String _query = '';
  String? _role;
  _Sort _sort = _Sort.newest;
  var _visible = _pageSize;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CompanyWork> get _filtered {
    var items = widget.works;
    if (_role != null) {
      items = [
        for (final w in items)
          if (w.roles.contains(_role)) w,
      ];
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = [
        for (final w in items)
          if (w.title.toLowerCase().contains(q)) w,
      ];
    }
    items = [...items]
      ..sort((a, b) {
        return switch (_sort) {
          _Sort.newest => _dateValue(b).compareTo(_dateValue(a)),
          _Sort.oldest => _dateValue(a).compareTo(_dateValue(b)),
          _Sort.topRated =>
            (b.externalReviewScore ?? b.tgReviewScore).compareTo(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = _roleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final filtered = _filtered;
    final shown = filtered.take(_visible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${context.t('library:catalog')} (${filtered.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (v) => setState(() {
            _query = v.trim();
            _visible = _pageSize;
          }),
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            hintText: context.t('library:searchTitles'),
            prefixIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Edgy(
          axis: .horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _role == null,
                    label: Text(
                      '${context.t('common:all')} (${widget.works.length})',
                    ),
                    onSelected: (_) => setState(() {
                      _role = null;
                      _visible = _pageSize;
                    }),
                  ),
                ),
                for (final role in roles)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _role == role.key,
                      label: Text(
                        '${role.key} (${role.value.humanizedCount()})',
                      ),
                      onSelected: (_) => setState(() {
                        _role = role.key;
                        _visible = _pageSize;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Edgy(
          axis: .horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  '${context.t('library:sortBy')}:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                for (final (sort, label) in [
                  (_Sort.newest, context.t('library:newestFirst')),
                  (_Sort.oldest, context.t('library:oldestFirst')),
                  (_Sort.topRated, context.t('library:topRated')),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: _sort == sort,
                      label: Text(label),
                      onSelected: (_) => setState(() {
                        _sort = sort;
                        _visible = _pageSize;
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
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
