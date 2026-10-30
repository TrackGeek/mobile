import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/user_list.dart';
import '../../services/list_service.dart';
import '../../utils/strings.dart';
import '../media/smooth_image.dart';

const _previewCount = 3;

class MediaListCard extends StatelessWidget {
  const MediaListCard({
    super.key,
    required this.list,
    required this.lists,
    this.onOpenMedia,
    this.onOpenUser,
  });

  final UserList list;
  final ListService lists;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final void Function(String username)? onOpenUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = list.mediaType;
    final previews = [
      for (final item in list.previewItems.take(_previewCount))
        (
          item: item,
          link: type == null ? null : listItemToLink(item, list.type),
        ),
    ];
    final remaining = list.itemCount - previews.length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => ListItemsSheet(
            list: list,
            lists: lists,
            onOpenMedia: onOpenMedia,
            onOpenUser: onOpenUser,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surfaceContainerHigh,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  children: [
                    for (final preview in previews)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 48,
                            height: 72,
                            child: preview.link?.image.isNotEmpty == true
                                ? SmoothImage(
                                    url: preview.link!.image,
                                    error: _fallback(
                                      context,
                                      (preview.link?.title).orPlaceholder(),
                                    ),
                                  )
                                : _fallback(
                                    context,
                                    (preview.link?.title).orPlaceholder(),
                                  ),
                          ),
                        ),
                      ),
                    if (remaining > 0)
                      Container(
                        width: 48,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: theme.colorScheme.surface,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          '+$remaining',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                list.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: theme.colorScheme.surface,
                    child: list.user.avatarUrl?.isNotEmpty == true
                        ? ClipOval(
                            child: SmoothImage(
                              url: list.user.avatarUrl!,
                              width: 20,
                              height: 20,
                              error: Text(
                                (list.user.name.isNotEmpty
                                        ? list.user.name
                                        : '?')[0]
                                    .toUpperCase(),
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          )
                        : Text(
                            (list.user.name.isNotEmpty
                                    ? list.user.name
                                    : '?')[0]
                                .toUpperCase(),
                            style: theme.textTheme.labelSmall,
                          ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      list.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

class ListItemsSheet extends StatefulWidget {
  const ListItemsSheet({
    super.key,
    required this.list,
    required this.lists,
    this.onOpenMedia,
    this.onOpenUser,
  });

  final UserList list;
  final ListService lists;
  final void Function(MediaType type, String slug)? onOpenMedia;
  final void Function(String username)? onOpenUser;

  @override
  State<ListItemsSheet> createState() => _ListItemsSheetState();
}

class _ListItemsSheetState extends State<ListItemsSheet> {
  final _scroll = ScrollController();
  final _items = <UserListItem>[];
  var _page = 1;
  var _pages = 1;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final language = L10nScope.of(context).language;
    try {
      final page = await widget.lists.listItems(
        widget.list.id,
        page: _page,
        itemsPerPage: 24,
        language: language,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _pages = page.pages ?? _page;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeLoadMore() {
    if (_loading || _page >= _pages) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 300) {
      return;
    }
    _page++;
    _loading = true;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = widget.list.mediaType;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, _) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.list.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.list.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: widget.onOpenUser == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onOpenUser!(widget.list.user.username);
                          },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: widget.list.user.avatarUrl?.isNotEmpty == true
                              ? ClipOval(
                                  child: SmoothImage(
                                    url: widget.list.user.avatarUrl!,
                                    width: 22,
                                    height: 22,
                                    error: Text(
                                      (widget.list.user.name.isNotEmpty
                                              ? widget.list.user.name
                                              : '?')[0]
                                          .toUpperCase(),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                )
                              : Text(
                                  (widget.list.user.name.isNotEmpty
                                          ? widget.list.user.name
                                          : '?')[0]
                                      .toUpperCase(),
                                  style: theme.textTheme.labelSmall,
                                ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.list.user.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty && !_loading
                  ? Center(
                      child: Text(
                        context.t('library:noItems'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                      itemCount: _items.length + (_loading ? 4 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _items.length) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          );
                        }
                        final item = _items[index];
                        final link = type == null
                            ? null
                            : listItemToLink(item, widget.list.type);
                        return _SheetItem(
                          link: link,
                          onTap: link == null || widget.onOpenMedia == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  widget.onOpenMedia!(link.type, link.slug);
                                },
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

class _SheetItem extends StatelessWidget {
  const _SheetItem({required this.link, this.onTap});

  final ListItemLink? link;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: link == null || link!.image.isEmpty
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SmoothImage(url: link!.image),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (link?.title).orPlaceholder(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
