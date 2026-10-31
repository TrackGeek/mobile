import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/person.dart';
import '../../services/auth_service.dart';
import '../../utils/content_types.dart';
import '../layout/adaptive_grid_delegate.dart';
import '../../utils/haptics.dart';
import '../layout/bottom_padding.dart';
import 'credit_card.dart';

enum _Role { all, cast, crew }

enum _Sort { newest, oldest, rating }

class PersonCreditsSection extends StatefulWidget {
  const PersonCreditsSection({
    super.key,
    required this.person,
    required this.visible,
    required this.user,
    required this.onOpenCredit,
    required this.onResetPaging,
    this.heading,
  });

  final Person person;
  final int visible;
  final SessionUser? user;
  final ValueChanged<PersonCredit> onOpenCredit;
  final VoidCallback onResetPaging;
  final String? heading;

  @override
  State<PersonCreditsSection> createState() => _CreditsSectionState();
}

class _CreditsSectionState extends State<PersonCreditsSection> {
  MediaType? _media;
  _Role _role = _Role.all;
  _Sort _sort = _Sort.newest;
  String _query = '';

  int get _activeFilters =>
      (_media != null ? 1 : 0) +
      (_role != _Role.all ? 1 : 0) +
      (_sort != _Sort.newest ? 1 : 0);

  void _openFilters({
    required List<({MediaType? value, String label, int count})> media,
    required bool showRole,
    required Map<String, int> roleCounts,
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
              widget.onResetPaging();
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
                            _role = _Role.all;
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
                if (showRole)
                  section(
                    context.t('library:role'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<_Role>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: _Role.all,
                            label: Text(context.t('common:all')),
                          ),
                          ButtonSegment(
                            value: _Role.cast,
                            label: Text(context.t('common:types.cast')),
                          ),
                          ButtonSegment(
                            value: _Role.crew,
                            label: Text(context.t('library:crew')),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (s) =>
                            update(() => _role = s.first),
                      ),
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

  List<PersonCredit> get _credits => widget.person.credits
      .where((credit) => isMediaTypeVisible(widget.user, credit.mediaType))
      .toList();

  Map<String, int> get _counts {
    final credits = _credits;
    return {
      'all': credits.length,
      'movie': credits.where((c) => c.mediaType == MediaType.movie).length,
      'tv': credits.where((c) => c.mediaType == MediaType.tv).length,
      'anime': credits.where((c) => c.mediaType == MediaType.anime).length,
      'manga': credits.where((c) => c.mediaType == MediaType.manga).length,
      'cast': credits.where((c) => c.isCast).length,
      'crew': credits.where((c) => !c.isCast).length,
    };
  }

  List<PersonCredit> get _filtered {
    final search = _query.trim().toLowerCase();
    final matching = _credits.where((credit) {
      if (_media != null && credit.mediaType != _media) return false;
      if (_role == _Role.cast && !credit.isCast) return false;
      if (_role == _Role.crew && credit.isCast) return false;
      if (search.isEmpty) return true;
      return credit.title.toLowerCase().contains(search) ||
          credit.roles.any((role) => role.toLowerCase().contains(search));
    }).toList();

    matching.sort((a, b) {
      if (_sort == _Sort.rating) {
        return (b.externalReviewScore ?? 0).compareTo(
          a.externalReviewScore ?? 0,
        );
      }
      final direction = _sort == _Sort.oldest ? -1 : 1;
      return ((b.year ?? 0) - (a.year ?? 0)) * direction;
    });
    return matching;
  }

  @override
  Widget build(BuildContext context) {
    if (_media != null && !isMediaTypeVisible(widget.user, _media!)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _media = null);
      });
    }
    final theme = Theme.of(context);
    final counts = _counts;
    final filtered = _filtered;
    final shown = filtered.take(widget.visible).toList();
    final activeFilters = _activeFilters;

    final mediaFilters = <({MediaType? value, String label, int count})>[
      (value: null, label: context.t('common:all'), count: counts['all']!),
      (
        value: MediaType.movie,
        label: context.t('common:types.movie', {'count': 2}),
        count: counts['movie']!,
      ),
      (
        value: MediaType.tv,
        label: context.t('common:types.tv', {'count': 2}),
        count: counts['tv']!,
      ),
      (
        value: MediaType.anime,
        label: context.t('common:types.anime', {'count': 2}),
        count: counts['anime']!,
      ),
      (
        value: MediaType.manga,
        label: context.t('common:types.manga', {'count': 2}),
        count: counts['manga']!,
      ),
    ];

    final visibleMedia = mediaFilters
        .where((filter) => filter.value == null || filter.count > 0)
        .toList();

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
            value: _Sort.rating,
            label: context.t('library:topRated'),
            icon: HugeIcons.strokeRoundedStar,
          ),
        ];

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.heading ?? context.t('library:filmography'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
                        onChanged: (value) => setState(() {
                          _query = value;
                          widget.onResetPaging();
                        }),
                        decoration: InputDecoration(
                          hintText: context.t('library:searchCredits'),
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
                          media: visibleMedia,
                          showRole: counts['cast']! > 0 && counts['crew']! > 0,
                          roleCounts: counts,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedFilm02,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('library:noCreditsFound'),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    context.t('common:noResultsDescription'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => CreditCard(
                  credit: shown[index],
                  onTap: () => widget.onOpenCredit(shown[index]),
                ),
                childCount: shown.length,
              ),
              gridDelegate: AdaptiveGridDelegate(
                context: context,
                maxCrossAxisExtent: 150,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.56,
              ),
            ),
          ),
      ],
    );
  }
}
