import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../models/media_type.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../utils/content_types.dart';
import 'review_item.dart';
import 'star_rating.dart';
import 'user_widgets.dart';
import '../layout/tg_refresh_indicator.dart';
import '../../utils/haptics.dart';

class UserReviewsTab extends StatefulWidget {
  const UserReviewsTab({
    super.key,
    required this.userId,
    required this.session,
    required this.reviews,
    this.initialType,
    this.onOpenMedia,
    this.onChanged,
  });

  final String userId;
  final SessionController session;
  final ReviewService reviews;
  final MediaType? initialType;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final VoidCallback? onChanged;

  @override
  State<UserReviewsTab> createState() => _UserReviewsTabState();
}

class _UserReviewsTabState extends State<UserReviewsTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <UserReview>[];
  final _search = TextEditingController();
  final _reacting = <String>{};
  Timer? _debounce;
  MediaType _type = MediaType.game;
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? MediaType.game;
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  String get _language => L10nScope.of(context).language;

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
      _loaded = true;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<dynamic> _fetch(int page) => widget.reviews.userReviews(
    _type,
    userId: widget.userId,
    query: _search.text,
    page: page,
    language: _language,
  );

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      _items.addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (_) {
      // retry on next scroll
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _load);
  }

  FeedReaction? _current(UserReview review) {
    final viewer = widget.session.user;
    if (viewer == null) return null;
    for (final reaction in review.reactions) {
      if (reaction.userId == viewer.id) return reaction;
    }
    return null;
  }

  Future<void> _react(UserReview review, String emoji) async {
    if (!_reacting.add(review.id)) return;
    final current = _current(review);
    try {
      final next = await widget.reviews.toggleReaction(
        review,
        emoji: emoji,
        currentReaction: current,
      );
      if (!mounted) return;
      setState(() {
        review.reactions.removeWhere(
          (r) => r.userId == widget.session.user?.id,
        );
        if (next != null) review.reactions.add(next);
      });
    } finally {
      _reacting.remove(review.id);
    }
  }

  Future<void> _delete(UserReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('user:deleteReviewTitle')),
        content: Text(context.t('user:deleteReviewConfirm')),
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
    try {
      await widget.reviews.deleteReview(review);
      if (mounted) {
        setState(() => _items.removeWhere((r) => r.id == review.id));
        widget.onChanged?.call();
      }
    } catch (_) {
      // leave item; error surfaced by refresh
    }
  }

  Future<void> _edit(UserReview review) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewEditSheet(review: review, reviews: widget.reviews),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewer = widget.session.user;
    final isOwner = viewer?.id == widget.userId;
    final visible = visibleMediaTypes(viewer);
    final types = [
      for (final t in MediaType.values)
        if (visible.contains(t)) t,
    ];
    if (!types.contains(_type)) _type = types.firstOrNull ?? MediaType.game;
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
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    DropdownButtonFormField<MediaType>(
                      initialValue: _type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final t in types)
                          DropdownMenuItem(
                            value: t,
                            child: Text(
                              context.t('common:types.${t.name}_other'),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null || value == _type) return;
                        setState(() {
                          _type = value;
                          _search.clear();
                        });
                        _load();
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
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
            else if (_loaded && _items.isEmpty)
              SliverFillRemaining(
                child: hasQuery
                    ? UserEmpty(
                        icon: HugeIcons.strokeRoundedSearch01,
                        title: context.t('common:noResults'),
                        description: context.t('common:noResultsDescription'),
                      )
                    : UserEmpty(
                        icon: HugeIcons.strokeRoundedEdit01,
                        title: context.t('library:noReviews'),
                        description: context.t('library:noReviewsDescription'),
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: _items.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index >= _items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final review = _items[index];
                    return ReviewItem(
                      review: review,
                      currentUserId: viewer?.id ?? '',
                      isOwner: isOwner,
                      onMediaTap: review.mediaEntityId == null
                          ? null
                          : () => widget.onOpenMedia?.call(
                              review.type,
                              review.mediaEntityId!,
                            ),
                      onEdit: () => _edit(review),
                      onDelete: () => _delete(review),
                      onReact: (emoji, current) => _react(review, emoji),
                      reacting: _reacting.contains(review.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewEditSheet extends StatefulWidget {
  const _ReviewEditSheet({required this.review, required this.reviews});

  final UserReview review;
  final ReviewService reviews;

  @override
  State<_ReviewEditSheet> createState() => _ReviewEditSheetState();
}

class _ReviewEditSheetState extends State<_ReviewEditSheet> {
  late final Map<String, double> _fields = Map.of(widget.review.fields);
  late double _overall = widget.review.overall;
  late final _summary = TextEditingController(text: widget.review.summary);
  late final _notes = TextEditingController(text: widget.review.notes);
  late final _story = TextEditingController(text: widget.review.story);
  late bool? _recommended = widget.review.recommended;
  bool _saving = false;

  @override
  void dispose() {
    _summary.dispose();
    _notes.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final config = reviewContent[widget.review.type]!;
    try {
      await widget.reviews.updateReview(
        widget.review,
        fields: {
          'overall': _overall,
          'summary': _summary.text.trim().isEmpty ? null : _summary.text.trim(),
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          if (config.hasStory)
            'story': _story.text.trim().isEmpty ? null : _story.text.trim(),
          'recommended': ?_recommended,
          for (final field in config.criteria)
            if (_fields[field] != null) field: _fields[field],
        },
      );
      HapticsHelper.success();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = reviewContent[widget.review.type]!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.review.mediaTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: StarRatingInput(
                value: _overall,
                onChanged: (v) => setState(() => _overall = v),
              ),
            ),
            const SizedBox(height: 16),
            for (final field in config.criteria) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t(
                        'feed:criteries.${config.criteriaLabels[field]}',
                      ),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  StarRatingInput(
                    value: _fields[field] ?? 0,
                    size: 20,
                    onChanged: (v) => setState(() => _fields[field] = v),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _summary,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.t('feed:summary'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (config.hasStory) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _story,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.t('feed:story'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.t('feed:notes'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilterChip(
                  label: Text(context.t('feed:recommended')),
                  selected: _recommended == true,
                  onSelected: (v) =>
                      setState(() => _recommended = v ? true : null),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
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
      ),
    );
  }
}
