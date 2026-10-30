import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../components/search/search_filters.dart';
import '../components/search/search_result_card.dart';
import '../components/search/user_result_tile.dart';
import '../components/search/user_search_skeleton.dart';
import '../components/search/search_error.dart';
import '../components/layout/content_frame.dart';
import '../controllers/search_controller.dart' as ctrl;
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/media_type.dart';
import '../models/search_item.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/genre_service.dart';
import '../services/media_detail_service.dart';
import '../services/person_service.dart';
import '../services/search_service.dart';
import '../services/user_service.dart';
import '../utils/content_types.dart';
import 'media_detail_page.dart';
import 'person_page.dart';
import '../components/layout/edgy.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.search,
    required this.details,
    required this.people,
    required this.favorites,
    required this.session,
    required this.users,
    required this.genres,
    required this.api,
    this.initialKind = const MediaSearchKind(MediaType.movie),
    this.initialFilters = const {},
    this.onOpenUser,
    this.onOpenSettings,
  });

  final SearchGateway search;
  final MediaDetailService details;
  final PersonService people;
  final FavoriteService favorites;
  final SessionController session;
  final UserService users;
  final GenreService genres;
  final ApiClient api;
  final SearchKind initialKind;
  final Map<String, String> initialFilters;
  final void Function(String username)? onOpenUser;
  final VoidCallback? onOpenSettings;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final ctrl.SearchController _controller;
  final _scroll = ScrollController();
  final _searchField = TextEditingController();

  static const _kinds = [
    MediaSearchKind(MediaType.movie),
    MediaSearchKind(MediaType.tv),
    MediaSearchKind(MediaType.game),
    MediaSearchKind(MediaType.anime),
    MediaSearchKind(MediaType.manga),
    MediaSearchKind(MediaType.book),
    PersonSearchKind(),
    UserSearchKind(),
  ];

  String _kindLabel(BuildContext context, SearchKind kind) => switch (kind) {
    MediaSearchKind(:final type) => context.t('common:types.${type.name}'),
    PersonSearchKind() => context.t('common:types.cast'),
    UserSearchKind() => context.t('common:profile'),
  };

  @override
  void initState() {
    super.initState();
    _controller = ctrl.SearchController(
      widget.search,
      initialKind: widget.initialKind,
      initialFilters: widget.initialFilters,
    );
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.search();
    });
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _controller.loadNextPage();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _searchField.dispose();
    super.dispose();
  }

  List<SearchKind> _visibleKinds(Set<MediaType> visible) => [
    for (final kind in _kinds)
      if (kind is! MediaSearchKind || visible.contains(kind.type)) kind,
  ];

  MediaDetailEnv get _env => (
    api: widget.api,
    session: widget.session,
    details: widget.details,
    people: widget.people,
    favorites: widget.favorites,
    progress: null,
    onOpenUser: widget.onOpenUser,
    onOpenGenre: _openGenreSearch,
    onOpenSettings: widget.onOpenSettings,
  );

  void _openGenreSearch(MediaType type, String genre) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPage(
          search: widget.search,
          details: widget.details,
          people: widget.people,
          favorites: widget.favorites,
          session: widget.session,
          users: widget.users,
          genres: widget.genres,
          api: widget.api,
          initialKind: MediaSearchKind(type),
          initialFilters: {'genres': genre},
          onOpenUser: widget.onOpenUser,
          onOpenSettings: widget.onOpenSettings,
        ),
      ),
    );
  }

  void _selectKind(SearchKind kind) {
    if (kind.path == _controller.kind.path) return;
    _searchField.clear();
    _controller.setKind(kind);
  }

  void _ensureVisibleKind(Set<MediaType> visible) {
    final kind = _controller.kind;
    if (kind is MediaSearchKind && !visible.contains(kind.type)) {
      final fallback = MediaType.values.firstWhere(
        visible.contains,
        orElse: () => MediaType.movie,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _selectKind(MediaSearchKind(fallback)),
      );
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _searchField.text = text;
    _controller.onQueryChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final visible = visibleMediaTypes(widget.session.user);
    _ensureVisibleKind(visible);
    final kinds = _visibleKinds(visible);
    return Scaffold(
      body: SafeArea(
        child: ContentFrame(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SearchBar(
                  controller: _searchField,
                  onChanged: _controller.onQueryChanged,
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  hintText: context.t('common:search'),
                  leading: Navigator.of(context).canPop()
                      ? IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowLeft01,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        )
                      : const HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
                  trailing: [
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => _controller.query.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchField.clear();
                                _controller.search('');
                              },
                            ),
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedClipboard,
                        size: 18,
                      ),
                      tooltip: context.t('common:clipboard.paste'),
                      onPressed: _paste,
                    ),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        if (_controller.kind is! MediaSearchKind) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          tooltip: context.t('common:filters'),
                          icon: Badge.count(
                            count: _controller.filters.length,
                            isLabelVisible: _controller.filters.isNotEmpty,
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedFilter,
                              size: 18,
                            ),
                          ),
                          onPressed: () => _openFilters(context),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 56 + (MediaQuery.textScalerOf(context).scale(14) - 14),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => Edgy(
                    axis: .horizontal,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: kinds.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final kind = kinds[index];
                        return ChoiceChip(
                          label: Text(_kindLabel(context, kind)),
                          selected: kind.path == _controller.kind.path,
                          onSelected: (_) => _selectKind(kind),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
    final kind = _controller.kind;
    if (kind is! MediaSearchKind) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SearchFilters(
              type: kind.type,
              values: _controller.filters,
              onChanged: _controller.setFilter,
              onClear: _controller.clearFilters,
              genreService: widget.genres,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isUser = _controller.kind is UserSearchKind;
    if (_controller.isLoading) {
      if (isUser) return const UserSearchSkeletonList(count: 8);
      return const Center(child: CircularProgressIndicator());
    }
    final error = _controller.error;
    if (error != null && _controller.results.isEmpty) {
      return SearchError(
        message: _errorMessage(context, error),
        onRetry: _controller.retry,
      );
    }
    if (_controller.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(icon: HugeIcons.strokeRoundedSearch02, size: 40),
            const SizedBox(height: 8),
            Text(
              context.t('common:noResults'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              context.t('common:noResultsDescription'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    if (isUser) {
      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount:
            _controller.results.length + (_controller.isLoadingMore ? 4 : 0),
        itemBuilder: (context, index) {
          if (index >= _controller.results.length) {
            return const UserSearchSkeleton();
          }
          final item = _controller.results[index];
          return UserResultTile(
            key: ValueKey(item.id),
            item: item,
            users: widget.users,
            session: widget.session,
          );
        },
      );
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent:
            290 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 3,
      ),
      itemCount:
          _controller.results.length + (_controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _controller.results.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final item = _controller.results[index];
        return SearchResultCard(
          item: item,
          onTap: switch (item.target) {
            SearchTarget.media when item.mediaType != null =>
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => mediaDetailPage(
                    type: item.mediaType!,
                    id: item.id,
                    details: widget.details,
                    env: _env,
                  ),
                ),
              ),
            SearchTarget.person => () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PersonPage(
                  request: PersonSlugRequest(item.id),
                  people: widget.people,
                  details: widget.details,
                  favorites: widget.favorites,
                  session: widget.session,
                  api: widget.api,
                  onOpenUser: widget.onOpenUser,
                  onOpenGenre: _openGenreSearch,
                  onOpenSettings: widget.onOpenSettings,
                ),
              ),
            ),
            SearchTarget.user when item.username != null =>
              () => widget.onOpenUser?.call(item.username!),
            _ => null,
          },
        );
      },
    );
  }

  String _errorMessage(BuildContext context, ApiException error) =>
      switch (error.failure) {
        ApiFailure.network => context.t('common:tryAgainLater'),
        ApiFailure.timeout => context.t('common:tryAgainLater'),
        ApiFailure.rateLimited => context.t('common:tryAgainLater'),
        _ => context.t('common:internalError'),
      };
}
