import 'dart:async';
import 'dart:io' show Platform;
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
  static const _seenKey = 'trackgeek.notifications.seenUnread';
  static const _channelId = 'trackgeek_notifications';
  static const checkInterval = Duration(hours: 1);

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
    await prefs.remove(_seenKey);
  }

  static Future<void> markSeen(int unreadCount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenKey, unreadCount);
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
      final count = await NotificationService(api)
          .unreadCount(language: l10n.language);
      final seen = prefs.getInt(_seenKey);
      await prefs.setInt(_seenKey, count);
      if (seen == null || count <= seen) return;
      await _plugin.initialize(settings: _settings);
      await _plugin.show(
        id: 0,
        title: l10n.t('common:notifications'),
        body: l10n.t('notifications:unreadCount', {'count': count}),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } finally {
      api.close();
    }
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
