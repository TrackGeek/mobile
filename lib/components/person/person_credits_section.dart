import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/person.dart';
import '../../services/auth_service.dart';
import '../../utils/content_types.dart';
import '../layout/adaptive_grid_delegate.dart';
import 'credit_card.dart';
import '../layout/edgy.dart';

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
  final Map<Object, GlobalKey> _chipKeys = {};

  void _ensureChipVisible(Object id) {
    final ctx = _chipKeys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
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
    final showMediaRow =
        mediaFilters.where((filter) => filter.count > 0).length > 2;

    final roleFilters = <({_Role value, String label, int count})>[
      (value: _Role.all, label: context.t('common:all'), count: counts['all']!),
      (
        value: _Role.cast,
        label: context.t('common:types.cast'),
        count: counts['cast']!,
      ),
      (
        value: _Role.crew,
        label: context.t('library:crew'),
        count: counts['crew']!,
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
              const SizedBox(height: 12),
              Edgy(
                axis: .horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (showMediaRow) ...[
                        for (final filter in visibleMedia)
                          _FilterChip(
                            key: _chipKeys.putIfAbsent((
                              'media',
                              filter.value,
                            ), GlobalKey.new),
                            label: filter.label,
                            count: filter.count,
                            active: _media == filter.value,
                            onTap: () {
                              setState(() {
                                _media = filter.value;
                                widget.onResetPaging();
                              });
                              _ensureChipVisible(('media', filter.value));
                            },
                          ),
                        const SizedBox(width: 12),
                      ],
                      if (counts['cast']! > 0 && counts['crew']! > 0) ...[
                        for (final filter in roleFilters)
                          _FilterChip(
                            key: _chipKeys.putIfAbsent((
                              'role',
                              filter.value,
                            ), GlobalKey.new),
                            label: filter.label,
                            count: filter.count,
                            active: _role == filter.value,
                            onTap: () {
                              setState(() {
                                _role = filter.value;
                                widget.onResetPaging();
                              });
                              _ensureChipVisible(('role', filter.value));
                            },
                          ),
                        const SizedBox(width: 12),
                      ],
                      for (final option in sortOptions)
                        _FilterChip(
                          key: _chipKeys.putIfAbsent((
                            'sort',
                            option.value,
                          ), GlobalKey.new),
                          label: option.label,
                          icon: option.icon,
                          active: _sort == option.value,
                          onTap: () {
                            setState(() => _sort = option.value);
                            _ensureChipVisible(('sort', option.value));
                          },
                        ),
                    ],
                  ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.count,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? count;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: active,
        onSelected: (_) => onTap(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon!, size: 14),
              const SizedBox(width: 6),
            ],
            Text(label),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: active
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
