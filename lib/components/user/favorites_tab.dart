import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/tg_theme.dart';
import '../media/sliver_poster_grid.dart';

import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/favorite.dart';
import '../../services/favorite_service.dart';
import '../../utils/content_types.dart';
import 'media_card.dart';
import 'user_widgets.dart';
import '../layout/tg_refresh_indicator.dart';

const _favoriteTypes = [
  ('Anime', 'common:types.anime_other'),
  ('Manga', 'common:types.manga_other'),
  ('TVShow', 'common:types.tv_other'),
  ('Movie', 'common:types.movie_other'),
  ('Game', 'common:types.game_other'),
  ('Book', 'common:types.book_other'),
  ('Person', 'common:types.cast_other'),
];

class UserFavoritesTab extends StatefulWidget {
  const UserFavoritesTab({
    super.key,
    required this.userId,
    required this.session,
    required this.favorites,
    this.initialType = 'Anime',
    this.onOpenItem,
  });

  final String userId;
  final SessionController session;
  final FavoriteService favorites;
  final String? initialType;
  final void Function(FavoriteItem item)? onOpenItem;

  @override
  State<UserFavoritesTab> createState() => _UserFavoritesTabState();
}

class _UserFavoritesTabState extends State<UserFavoritesTab>
    with AutomaticKeepAliveClientMixin {
  final _items = <Favorite>[];
  final _search = TextEditingController();
  Timer? _debounce;
  String _type = 'Anime';
  bool _loading = false;
  bool _loaded = false;
  bool _removing = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'Anime';
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
      final page = await widget.favorites.favoritesByUser(
        widget.userId,
        query: _search.text,
        language: _language,
      );
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
      _loaded = true;
      while (_hasNext && mounted) {
        final next = await widget.favorites.favoritesByUser(
          widget.userId,
          page: _page + 1,
          query: _search.text,
          language: _language,
        );
        _items.addAll(next.items);
        _page = next.inPage;
        _hasNext = next.hasNextPage;
      }
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _load);
  }

  Future<void> _remove(FavoriteItem item) async {
    if (_removing) return;
    setState(() => _removing = true);
    final index = _items.indexWhere((f) => f.id == item.id);
    final removed = index == -1 ? null : _items.removeAt(index);
    try {
      await widget.favorites.remove(item.target, item.mediaId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(item.title)));
      }
    } catch (_) {
      if (removed != null && mounted) {
        _items.insert(index.clamp(0, _items.length), removed);
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewer = widget.session.user;
    final visible = visibleMediaTypes(viewer);
    final isOwner = viewer?.id == widget.userId;
    final items = [
      for (final favorite in _items)
        if (favorite.type == _type) ?favoriteToItem(favorite),
    ];
    final hasQuery = _search.text.trim().isNotEmpty;
    return TgRefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final (type, labelKey) in _favoriteTypes)
                        DropdownMenuItem(
                          value: type,
                          enabled:
                              type == 'Person' ||
                              visible.any((t) => t.name == _slugFor(type)),
                          child: Text(context.t(labelKey)),
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
          else if (_loaded && items.isEmpty)
            SliverFillRemaining(
              child: hasQuery
                  ? UserEmpty(
                      icon: HugeIcons.strokeRoundedSearch01,
                      title: context.t('common:noResults'),
                      description: context.t('common:noResultsDescription'),
                    )
                  : UserEmpty(
                      icon: HugeIcons.strokeRoundedFavourite,
                      title: context.t('user:noFavorites'),
                      description: context.t('user:noFavoritesDescription'),
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverPosterGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: MediaCard(
                          title: item.title,
                          image: item.image,
                          onTap: () => widget.onOpenItem?.call(item),
                        ),
                      ),
                      if (isOwner)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filled(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 14,
                            ),
                            iconSize: 14,
                            visualDensity: VisualDensity.compact,
                            style: IconButton.styleFrom(
                              backgroundColor: TgColors.scrim,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(28, 28),
                            ),
                            onPressed: () => _remove(item),
                          ),
                        ),
                    ],
                  );
                }, childCount: items.length),
              ),
            ),
        ],
      ),
    );
  }

  String _slugFor(String type) => switch (type) {
    'TVShow' => 'tv',
    _ => type.toLowerCase(),
  };
}
