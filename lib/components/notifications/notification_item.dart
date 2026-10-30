import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/notification.dart';
import '../user/user_widgets.dart';
import '../media/smooth_image.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.busy,
    required this.onToggleRead,
    required this.onDelete,
    this.onOpenUser,
    this.onOpenMedia,
    this.onOpenLink,
  });

  final AppNotification notification;
  final bool busy;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;
  final ValueChanged<String>? onOpenUser;
  final void Function(MediaType type, String id)? onOpenMedia;
  final ValueChanged<String>? onOpenLink;

  bool get _reopened => notification.metadata?['reopened'] == true;

  String _headline(BuildContext context, String title) {
    final event = notification.releaseEvent!;
    final unit = event.unitNumber;
    final container = event.containerNumber;
    return switch (event.type) {
      'NewEpisodeReleased' =>
        unit == null
            ? context.t('notifications:release.episodeUnknown', {
                'title': title,
              })
            : container == null
            ? context.t('notifications:release.episode', {
                'number': '$unit',
                'title': title,
              })
            : context.t('notifications:release.seasonEpisode', {
                'season': '$container',
                'number': '$unit',
                'title': title,
              }),
      'NewChapterReleased' =>
        unit == null
            ? context.t('notifications:release.chapterUnknown', {
                'title': title,
              })
            : context.t('notifications:release.chapter', {
                'number': '$unit',
                'title': title,
              }),
      'NewGameReleased' => context.t('notifications:release.game', {
        'title': title,
      }),
      'SequelAdded' => context.t('notifications:release.sequel', {
        'title': title,
      }),
      _ => title,
    };
  }

  List<List<dynamic>> get _releaseIcon =>
      switch (notification.releaseEvent?.type) {
        'NewEpisodeReleased' => HugeIcons.strokeRoundedMonitorPlay,
        'NewChapterReleased' => HugeIcons.strokeRoundedBookOpen02,
        'NewGameReleased' => HugeIcons.strokeRoundedGame,
        'SequelAdded' => HugeIcons.strokeRoundedSparkles,
        _ => HugeIcons.strokeRoundedBell,
      };

  String _systemText(BuildContext context, String key) {
    final metadata = notification.metadata;
    if (metadata == null) return '';
    final keyValue = metadata['${key}Key'];
    final params = <String, Object?>{...metadata};
    final missionKey = metadata['missionKey'];
    if (missionKey is String) {
      params['missionName'] = context.t('missions:names.$missionKey');
    }
    if (keyValue is String && keyValue.isNotEmpty) {
      final resolved = context.t(
        keyValue.contains(':') ? keyValue : 'notifications:$keyValue',
        params,
      );
      if (resolved != keyValue) return resolved;
    }
    final literal = metadata[key];
    return literal is String ? literal : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final event = notification.releaseEvent;
    final media = event?.media;
    final detailType = event?.detailType;
    final detailId = media?.detailId;
    final openDetail = detailType != null && detailId != null
        ? () => onOpenMedia?.call(detailType, detailId)
        : null;
    final created = DateTime.tryParse(notification.createdAt);
    final timestamp = created == null
        ? ''
        : DateFormat.yMd(locale).add_jm().format(created.toLocal());

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: EdgeInsets.zero,
      color: notification.isRead
          ? null
          : theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!notification.isRead)
              Padding(
                padding: const EdgeInsets.only(top: 18, right: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (event != null)
              GestureDetector(
                onTap: openDetail,
                child: Container(
                  width: 48,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child:
                        media?.coverUrl != null && media!.coverUrl!.isNotEmpty
                        ? SmoothImage(
                            url: media.coverUrl!,
                            error: Center(
                              child: HugeIcon(
                                icon: _releaseIcon,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Center(
                            child: HugeIcon(
                              icon: _releaseIcon,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              )
            else if (notification.isSystem || notification.actor == null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMegaphone02,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: notification.actor!.username.isEmpty
                    ? null
                    : () => onOpenUser?.call(notification.actor!.username),
                child: UserAvatar(
                  name: notification.actor!.name.isNotEmpty
                      ? notification.actor!.name
                      : notification.actor!.username,
                  avatarUrl: notification.actor!.avatarUrl,
                  size: 36,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: event != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _headline(context, media?.title ?? event.title),
                              style: titleStyle,
                            ),
                            if (_reopened)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedRotateCcw,
                                      size: 10,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      context.t(
                                        'notifications:release.reopened',
                                      ),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (event.unitTitle != null &&
                            event.unitTitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              event.unitTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mutedStyle,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (openDetail != null)
                                GestureDetector(
                                  onTap: openDetail,
                                  child: Text(
                                    context.t(
                                      'notifications:release.viewTitle',
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              if (timestamp.isNotEmpty)
                                Text(timestamp, style: mutedStyle),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (notification.isSystem ||
                                notification.actor == null)
                              Text(
                                _systemText(context, 'title').isNotEmpty
                                    ? _systemText(context, 'title')
                                    : context.t('notifications:system'),
                                style: titleStyle,
                              )
                            else ...[
                              GestureDetector(
                                onTap: notification.actor!.username.isEmpty
                                    ? null
                                    : () => onOpenUser?.call(
                                        notification.actor!.username,
                                      ),
                                child: Text(
                                  notification.actor!.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                              ),
                              Text(
                                context.t(
                                  'notifications:types.${notification.type}',
                                ),
                                style: mutedStyle,
                              ),
                              if (notification.reaction != null &&
                                  notification.reaction!.emoji.isNotEmpty)
                                Text(notification.reaction!.emoji),
                            ],
                            if (timestamp.isNotEmpty) ...[
                              Text('•', style: mutedStyle),
                              Text(timestamp, style: mutedStyle),
                            ],
                          ],
                        ),
                        if (notification.comment != null &&
                            notification.comment!.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '“${notification.comment!.content}”',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mutedStyle,
                            ),
                          ),
                        if (notification.isSystem &&
                            _systemText(context, 'description').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _systemText(context, 'description'),
                              style: mutedStyle,
                            ),
                          ),
                        if (notification.isSystem &&
                            notification.metadata?['url'] is String)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GestureDetector(
                              onTap: () => onOpenLink?.call(
                                notification.metadata!['url'] as String,
                              ),
                              child: Text(
                                context.t('notifications:learnMore'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : onToggleRead,
                  tooltip: context.t(
                    notification.isRead
                        ? 'notifications:markAsUnread'
                        : 'notifications:markAsRead',
                  ),
                  icon: HugeIcon(
                    icon: notification.isRead
                        ? HugeIcons.strokeRoundedMail01
                        : HugeIcons.strokeRoundedMailOpen,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : onDelete,
                  tooltip: context.t('common:delete'),
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
