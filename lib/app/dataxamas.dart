import 'package:dataxamas/dataxamas.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/widgets.dart';

const _apiKey = String.fromEnvironment('DATAXAMAS_API_KEY');
const _baseUrl = String.fromEnvironment(
  'DATAXAMAS_BASE_URL',
  defaultValue: 'https://dataxamas.com',
);

/// Without `DATAXAMAS_API_KEY` every call is a no-op, so local runs and tests
/// never reach Dataxamas.
final dataxamas = Analytics._(
  _apiKey.isEmpty
      ? null
      : Dataxamas(
          apiKey: _apiKey,
          baseUrl: _baseUrl,
          environment: kReleaseMode ? 'production' : 'development',
        ),
);

class Analytics {
  Analytics._(this._client);

  final Dataxamas? _client;
  String? _rootScreen;

  late final NavigatorObserver? observer = _createObserver();

  NavigatorObserver? _createObserver() {
    final client = _client;
    if (client == null) return null;
    return DataxamasNavigatorObserver(
      client.tracking,
      // The root route hosts the auth gate or the shell tabs, so its screen is
      // whatever [root] reported last.
      nameExtractor: (settings) => settings.name == Navigator.defaultRouteName
          ? _rootScreen
          : settings.name,
    );
  }

  Future<void> start() async => _client?.tracking.start();

  Widget wrap(Widget child) {
    final client = _client;
    if (client == null) return child;
    return DataxamasWidget(client: client, child: child);
  }

  /// Screen shown by the root route. With [visible] false the screen is only
  /// kept, to be reported once the routes on top of it are popped.
  void root(String path, {bool visible = true}) {
    _rootScreen = path;
    if (visible) _client?.tracking.screen(path);
  }

  void track(String name, [Map<String, Object?>? data]) =>
      _client?.tracking.track(name, data);

  void identify(String? userId) => _client?.tracking.identify(userId);

  void openedFromLink(Uri link) => _client?.tracking.openedFromLink(link);
}
