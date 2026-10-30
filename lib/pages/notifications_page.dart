import '../app/scrollable_tab.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../components/layout/content_frame.dart';
import '../styles/tg_layout.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/notifications/notification_list.dart';
import '../l10n/l10n_context.dart';
import '../models/media_type.dart';
import '../services/notification_service.dart';
import '../utils/haptics.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.notifications,
    this.onOpenUser,
    this.onOpenMedia,
    this.onUnreadChanged,
  });

  final NotificationService notifications;
  final ValueChanged<String>? onOpenUser;
  final void Function(MediaType type, String id)? onOpenMedia;
  final ValueChanged<int>? onUnreadChanged;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    implements ScrollableTab {
  final _notifScroll = ScrollController();
  final _listKey = GlobalKey<NotificationListState>();
  int _unread = 0;
  int _total = 0;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshUnread());
  }

  @override
  void scrollToTop() {
    final scroller = _notifScroll;
    final atTop = !scroller.hasClients || scroller.offset <= 0;
    if (!atTop) {
      scroller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
  }

  @override
  void dispose() {
    _notifScroll.dispose();
    super.dispose();
  }

  String get _language => L10nScope.of(context).language;

  Future<void> _refreshUnread() async {
    try {
      final count = await widget.notifications.unreadCount(language: _language);
      if (!mounted) return;
      setState(() => _unread = count);
      widget.onUnreadChanged?.call(count);
    } catch (_) {
      // badge keeps last value
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_pending) return;
    setState(() => _pending = true);
    try {
      await action();
      await _listKey.currentState?.load();
      await _refreshUnread();
    } catch (_) {
      if (mounted) {
        HapticsHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('common:somethingWentWrong'))),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(dialogContext.t('notifications:deleteAllTitle')),
            content: Text(
              dialogContext.t('notifications:deleteAllDescription'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.t('common:cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                child: Text(dialogContext.t('notifications:deleteAll')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await _mutate(widget.notifications.deleteAll);
  }

  void _openLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _notifScroll,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('common:notifications')),
              Text(
                context.t('notifications:description'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: context.t('notifications:markAllAsRead'),
              onPressed: _pending || _unread == 0
                  ? null
                  : () => _mutate(widget.notifications.markAllRead),
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedMailOpen),
            ),
            PopupMenuButton<String>(
              tooltip: context.t('common:showMore'),
              onSelected: (value) {
                switch (value) {
                  case 'unread':
                    _mutate(widget.notifications.markAllUnread);
                  case 'delete':
                    _confirmDeleteAll();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'unread',
                  enabled: !_pending && _total > 0 && _unread != _total,
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedMail01,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(context.t('notifications:markAllAsUnread')),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  enabled: !_pending && _total > 0,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('notifications:deleteAll'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ContentFrame(
          maxWidth: TgLayout.readingWidth,
          child: NotificationList(
            key: _listKey,
            scrollController: _notifScroll,
            notifications: widget.notifications,
            onChanged: (total) => setState(() => _total = total ?? 0),
            onOpenUser: widget.onOpenUser,
            onOpenMedia: widget.onOpenMedia,
            onOpenLink: _openLink,
          ),
        ),
      ),
    );
  }
}
