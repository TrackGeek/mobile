import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../app/api_config.dart';
import '../app/server_config.dart';
import '../controllers/session_controller.dart';
import '../l10n/trackgeek_localizations.dart';
import '../models/notification.dart';
import 'api_client.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void notificationCheckDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      await NotificationAlerts.checkOnce();
    } catch (_) {}
    return true;
  });
}

class NotificationAlerts {
  NotificationAlerts._();

  static const taskName = 'trackgeek.notifications.check';
  static const _shownKey = 'trackgeek.notifications.shownIds';
  static const _channelId = 'trackgeek_notifications';
  static const checkInterval = Duration(minutes: 15);

  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> enable() async {
    if (!_supported) return;
    await _plugin.initialize(settings: _settings);
    await _requestPermission();
    await Workmanager().initialize(notificationCheckDispatcher);
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: checkInterval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> disable() async {
    if (!_supported) return;
    await Workmanager().cancelByUniqueName(taskName);
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shownKey);
  }

  static Future<void> markSeen(int unreadCount) async {
    if (!_supported || unreadCount > 0) return;
    await _plugin.cancelAll();
  }

  static Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> checkOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SessionController.tokenKey);
    if (token == null || token.isEmpty) return;
    final baseUrl =
        prefs.getString(ServerConfig.prefsKey) ?? ServerConfig.defaultUrl;

    final l10n = await _loadLocalizations();

    final api = ApiClient(
      config: ApiConfig(baseUrl: baseUrl),
      client: http.Client(),
    )..bearerToken = token;
    try {
      final page = await NotificationService(api)
          .notifications(itemsPerPage: 20, language: l10n.language);
      final unread = page.items.where((n) => !n.isRead).toList();
      final known = prefs.getStringList(_shownKey);
      final shown = <String>{...?known};
      final fresh = known == null
          ? <AppNotification>[]
          : unread.where((n) => !shown.contains(n.id)).toList();
      shown.addAll(unread.map((n) => n.id));
      final alive = page.items.map((n) => n.id).toSet();
      shown.retainWhere(alive.contains);
      await prefs.setStringList(_shownKey, shown.toList());
      if (fresh.isEmpty) return;
      await _plugin.initialize(settings: _settings);
      for (final n in fresh.reversed.take(10)) {
        await _show(n, l10n);
      }
    } finally {
      api.close();
    }
  }

  static Future<void> _show(
    AppNotification n,
    TrackGeekLocalizations l10n,
  ) async {
    final content = _content(n, l10n);
    final imagePath = await _downloadImage(_imageUrl(n));
    await _plugin.show(
      id: n.id.hashCode & 0x7fffffff,
      title: content.title,
      body: content.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Notifications',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: _channelId,
          largeIcon: imagePath == null
              ? null
              : FilePathAndroidBitmap(imagePath),
          styleInformation: content.body == null
              ? null
              : BigTextStyleInformation(content.body!),
        ),
        iOS: DarwinNotificationDetails(
          attachments: imagePath == null
              ? null
              : [DarwinNotificationAttachment(imagePath)],
        ),
      ),
    );
  }

  static String? _imageUrl(AppNotification n) {
    final cover = n.releaseEvent?.media?.coverUrl;
    if (n.releaseEvent != null) return cover;
    if (n.isSystem) return null;
    return n.actor?.avatarUrl;
  }

  static Future<String?> _downloadImage(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      final ext = url.toLowerCase().contains('.png') ? 'png' : 'jpg';
      final file = File(
        '${Directory.systemTemp.path}/tg_notif_${url.hashCode & 0x7fffffff}.$ext',
      );
      await file.writeAsBytes(res.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static ({String title, String? body}) _content(
    AppNotification n,
    TrackGeekLocalizations l10n,
  ) {
    final event = n.releaseEvent;
    if (event != null) {
      final title = event.media?.title ?? event.title;
      final unit = event.unitNumber;
      final container = event.containerNumber;
      final headline = switch (event.type) {
        'NewEpisodeReleased' =>
          unit == null
              ? l10n.t('notifications:release.episodeUnknown', {'title': title})
              : container == null
              ? l10n.t('notifications:release.episode', {
                  'number': '$unit',
                  'title': title,
                })
              : l10n.t('notifications:release.seasonEpisode', {
                  'season': '$container',
                  'number': '$unit',
                  'title': title,
                }),
        'NewChapterReleased' =>
          unit == null
              ? l10n.t('notifications:release.chapterUnknown', {'title': title})
              : l10n.t('notifications:release.chapter', {
                  'number': '$unit',
                  'title': title,
                }),
        'NewGameReleased' => l10n.t('notifications:release.game', {
          'title': title,
        }),
        'SequelAdded' => l10n.t('notifications:release.sequel', {
          'title': title,
        }),
        _ => title,
      };
      final unitTitle = event.unitTitle;
      return (
        title: headline,
        body: unitTitle != null && unitTitle.isNotEmpty ? unitTitle : null,
      );
    }
    if (n.isSystem || n.actor == null) {
      final title = _systemText(n, l10n, 'title');
      final description = _systemText(n, l10n, 'description');
      return (
        title: title.isNotEmpty ? title : l10n.t('notifications:system'),
        body: description.isNotEmpty ? description : null,
      );
    }
    final actor = n.actor!;
    final name = actor.username.isNotEmpty ? actor.username : actor.name;
    final emoji = n.reaction?.emoji ?? '';
    final comment = n.comment?.content ?? '';
    return (
      title:
          '$name ${l10n.t('notifications:types.${n.type}')}'
          '${emoji.isEmpty ? '' : ' $emoji'}',
      body: comment.isEmpty ? null : '“$comment”',
    );
  }

  static String _systemText(
    AppNotification n,
    TrackGeekLocalizations l10n,
    String key,
  ) {
    final metadata = n.metadata;
    if (metadata == null) return '';
    final keyValue = metadata['${key}Key'];
    final params = <String, Object?>{...metadata};
    final missionKey = metadata['missionKey'];
    if (missionKey is String) {
      params['missionName'] = l10n.t('missions:names.$missionKey');
    }
    if (keyValue is String && keyValue.isNotEmpty) {
      final resolved = l10n.t(
        keyValue.contains(':') ? keyValue : 'notifications:$keyValue',
        params,
      );
      if (resolved != keyValue) return resolved;
    }
    final literal = metadata[key];
    return literal is String ? literal : '';
  }

  static Future<TrackGeekLocalizations> _loadLocalizations() async {
    try {
      return await TrackGeekLocalizations.load(
        PlatformDispatcher.instance.locale,
      );
    } catch (_) {
      return TrackGeekLocalizations.load(const Locale('en', 'US'));
    }
  }
}
