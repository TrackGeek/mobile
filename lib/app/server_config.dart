import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

class ServerConfig {
  ServerConfig(this._api);

  static const defaultUrl = 'https://api.trackgeek.net';
  static const prefsKey = 'trackgeek.server.url';
  static const _key = prefsKey;

  final ApiClient _api;
  String? _custom;

  String? get custom => _custom;
  bool get isDefault => _custom == null;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != defaultUrl) {
      _custom = saved;
      _api.setBaseUrl(saved, allowInsecure: true);
    }
  }

  Future<void> useDefault() async {
    _custom = null;
    _api.setBaseUrl(defaultUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> useCustom(String url) async {
    _api.setBaseUrl(url, allowInsecure: true);
    _custom = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}
