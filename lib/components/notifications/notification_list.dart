import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import 'notification_item.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({
    super.key,
    required this.notifications,
    required this.onChanged,
    this.onOpenUser,
    this.onOpenMedia,
    this.onOpenLink,
  });

  final NotificationService notifications;
  final void Function(int? total) onChanged;
  final ValueChanged<String>? onOpenUser;
  final void Function(MediaType type, String id)? onOpenMedia;
  final ValueChanged<String>? onOpenLink;

  @override
  State<NotificationList> createState() => NotificationListState();
}

class NotificationListState extends State<NotificationList> {
  final _scroll = ScrollController();
  final _items = <AppNotification>[];
  int _page = 1;
  bool _loaded = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _error = false;
  bool _busy = false;

  String get _language => L10nScope.of(context).language;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await widget.notifications.notifications(
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.inPage;
        _hasMore = page.hasNextPage;
        _loaded = true;
        _loading = false;
      });
      widget.onChanged(page.total);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.notifications.notifications(
        page: _page + 1,
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _page = page.inPage;
        _items.addAll(page.items);
        _hasMore = page.hasNextPage;
      });
    } catch (_) {
      // keep previous pages
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('common:somethingWentWrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleRead(AppNotification notification) => _mutate(
    () => notification.isRead
        ? widget.notifications.markUnread(notification.id)
        : widget.notifications.markRead(notification.id),
  );

  void _delete(AppNotification notification) =>
      _mutate(() => widget.notifications.delete(notification.id));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: Builder(
        builder: (context) {
          if (_loading && !_loaded) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    height: 80,
                    margin: EdgeInsets.only(top: i == 0 ? 0 : 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ],
            );
          }
          if (_error && _items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 320,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedAlertCircle,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.t('common:somethingWentWrong'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.t('common:tryAgainLater'),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: load,
                          child: Text(context.t('common:tryAgain')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          if (_items.isEmpty && _loaded) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 320,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedBellOff,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.t('notifications:empty.title'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            context.t('notifications:empty.description'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _items.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= _items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final notification = _items[index];
              return NotificationItem(
                notification: notification,
                busy: _busy,
                onToggleRead: () => _toggleRead(notification),
                onDelete: () => _delete(notification),
                onOpenUser: widget.onOpenUser,
                onOpenMedia: widget.onOpenMedia,
                onOpenLink: widget.onOpenLink,
              );
            },
          );
        },
      ),
    );
  }
}
