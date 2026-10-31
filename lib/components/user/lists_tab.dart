import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/paginated_page.dart';
import '../../models/user_list.dart';
import '../../services/list_service.dart';
import '../../utils/strings.dart';
import 'user_widgets.dart';
import '../media/smooth_image.dart';
import '../layout/tg_refresh_indicator.dart';
import '../../utils/haptics.dart';
import '../../utils/adaptive_sheet_route.dart';
import '../../utils/numbers.dart';

class UserListsTab extends StatefulWidget {
  const UserListsTab({
    super.key,
    required this.userId,
    required this.session,
    required this.lists,
    this.isOwner = false,
    this.onOpenMedia,
    this.onChanged,
  });

  final String userId;
  final SessionController session;
  final ListService lists;
  final bool isOwner;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final VoidCallback? onChanged;

  @override
  State<UserListsTab> createState() => _UserListsTabState();
}

class _UserListsTabState extends State<UserListsTab>
    with AutomaticKeepAliveClientMixin {
  final _groups = <UserListGroup>[];
  final _search = TextEditingController();
  Timer? _debounce;
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
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      _groups
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

  Future<PaginatedPage<UserListGroup>> _fetch(int page) =>
      widget.lists.listsByUser(
        widget.userId,
        query: _search.text,
        page: page,
        language: L10nScope.read(context).language,
      );

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      _groups.addAll(page.items);
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

  Future<void> _edit(UserList list) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ListEditDialog(list: list, lists: widget.lists),
    );
    if (saved == true) {
      widget.onChanged?.call();
      _load();
    }
  }

  Future<void> _delete(UserList list) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(context.t('user:confirmDeleteList')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('common:cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('common:delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.lists.deleteList(list.id);
      widget.onChanged?.call();
      _load();
    } catch (_) {
      // keep list on failure
    }
  }

  void _open(UserList list) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(
      _ListItemsSheet(
        list: list,
        lists: widget.lists,
        isOwner: widget.isOwner,
        onOpenMedia: widget.onOpenMedia,
        onChanged: () {
          widget.onChanged?.call();
          _load();
        },
      ).asAdaptiveSheetRoute<void>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final filtered = _groups;
    final hasAny = filtered.any((g) => g.lists.isNotEmpty);
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: context.t('common:search'),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 18,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),
            if (_loading && _groups.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _groups.isEmpty)
              SliverFillRemaining(child: UserError(onRetry: _load))
            else if (_loaded && !hasAny)
              SliverFillRemaining(
                child: hasQuery
                    ? UserEmpty(
                        icon: HugeIcons.strokeRoundedSearch01,
                        title: context.t('common:noResults'),
                        description: context.t('common:noResultsDescription'),
                      )
                    : UserEmpty(
                        icon: HugeIcons.strokeRoundedListView,
                        title: context.t('common:lists'),
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList.separated(
                  itemCount: filtered.length + (_loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    if (index >= filtered.length) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final group = filtered[index];
                    if (group.lists.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final list in group.lists)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ListCard(
                              list: list,
                              isOwner: widget.isOwner,
                              onTap: () => _open(list),
                              onEdit: () => _edit(list),
                              onDelete: () => _delete(list),
                            ),
                          ),
                      ],
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

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.list,
    required this.isOwner,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final UserList list;
  final bool isOwner;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (list.description != null &&
                          list.description!.isNotEmpty)
                        Text(
                          list.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        list.itemCount.humanizedCount(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      size: 16,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.t('user:editList'),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.t('user:deleteList'),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            if (list.previewItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    for (final item in list.previewItems.take(4))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: SmoothImage(
                              url:
                                  '${item.media['imageUrl'] ?? item.media['coverUrl'] ?? item.media['posterUrl'] ?? ''}',
                              height: 60,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListEditDialog extends StatefulWidget {
  const _ListEditDialog({required this.list, required this.lists});

  final UserList list;
  final ListService lists;

  @override
  State<_ListEditDialog> createState() => _ListEditDialogState();
}

class _ListEditDialogState extends State<_ListEditDialog> {
  late final _name = TextEditingController(text: widget.list.name);
  late final _description = TextEditingController(
    text: widget.list.description,
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.lists.updateList(
        widget.list.id,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.t('user:listUpdated'))));
        HapticsHelper.success();
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.t('user:editList')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: context.t('user:listName'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _description,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.t('user:listDescription'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.t('common:cancel')),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(context.t('common:save')),
      ),
    ],
  );
}

class _ListItemsSheet extends StatefulWidget {
  const _ListItemsSheet({
    required this.list,
    required this.lists,
    required this.isOwner,
    this.onOpenMedia,
    this.onChanged,
  });

  final UserList list;
  final ListService lists;
  final bool isOwner;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final VoidCallback? onChanged;

  @override
  State<_ListItemsSheet> createState() => _ListItemsSheetState();
}

class _ListItemsSheetState extends State<_ListItemsSheet> {
  final _items = <UserListItem>[];
  final _removing = <String>{};
  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.lists.listItems(widget.list.id);
      _items
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.lists.listItems(
        widget.list.id,
        page: _page + 1,
      );
      _items.addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
    } catch (_) {
      // retry on scroll
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _remove(UserListItem item) async {
    if (!_removing.add(item.id)) return;
    try {
      await widget.lists.removeItem(widget.list.id, item.id);
      setState(() => _items.removeWhere((i) => i.id == item.id));
      widget.onChanged?.call();
    } finally {
      _removing.remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.list.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? UserError(onRetry: _load)
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        final item = _items[index];
                        final link = listItemToLink(item, widget.list.type);
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SmoothImage(
                                  url: link?.image ?? '',
                                  width: 40,
                                  height: 56,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: link == null
                                      ? null
                                      : () => widget.onOpenMedia?.call(
                                          link.type,
                                          link.slug,
                                        ),
                                  child: Text(
                                    (link?.title).orPlaceholder(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.isOwner)
                                IconButton(
                                  icon: _removing.contains(item.id)
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : HugeIcon(
                                          icon: HugeIcons.strokeRoundedDelete02,
                                          size: 16,
                                          color: theme.colorScheme.error,
                                        ),
                                  tooltip: context.t('user:removeItem'),
                                  onPressed: () => _remove(item),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
