import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/numbers.dart';

class TrackGeekLocalizations extends ChangeNotifier {
  TrackGeekLocalizations._(this._resources, this._language) {
    setNumberLocale(_language);
  }

  static const String fallbackLanguage = 'en-US';

  static const List<String> supportedLanguages = [
    'af-ZA',
    'ar-SA',
    'ca-ES',
    'cs-CZ',
    'da-DK',
    'de-DE',
    'el-GR',
    'en-US',
    'es-ES',
    'fi-FI',
    'fr-FR',
    'he-IL',
    'hu-HU',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'nl-NL',
    'no-NO',
    'pl-PL',
    'pt-BR',
    'pt-PT',
    'ro-RO',
    'ru-RU',
    'sr-SP',
    'sv-SE',
    'tr-TR',
    'uk-UA',
    'vi-VN',
    'zh-CN',
    'zh-TW',
  ];

  static const List<String> namespaces = [
    'api',
    'app',
    'auth',
    'comments',
    'common',
    'cosmetics',
    'feed',
    'library',
    'medals',
    'missions',
    'notifications',
    'pages',
    'settings',
    'shop',
    'user',
    'xp',
  ];

  final Map<String, Map<String, String>> _resources;
  String _language;

  String get language => _language;

  static String resolveLanguage(Locale locale) {
    final tag = '${locale.languageCode}-${locale.countryCode}'.replaceAll(
      '-null',
      '',
    );
    if (supportedLanguages.contains(tag)) return tag;
    if (supportedLanguages.contains(locale.languageCode)) {
      return locale.languageCode;
    }
    return switch (locale.languageCode) {
      'pt' => 'pt-PT',
      'zh' => 'zh-CN',
      'en' => fallbackLanguage,
      'no' || 'nb' || 'nn' => 'no-NO',
      'sr' => 'sr-SP',
      'he' || 'iw' => 'he-IL',
      _ => fallbackLanguage,
    };
  }

  static Future<TrackGeekLocalizations> load(
    Locale deviceLocale, {
    Future<String> Function(String path)? read,
  }) async {
    final loader = read ?? rootBundle.loadString;
    final language = resolveLanguage(deviceLocale);
    final resources = <String, Map<String, String>>{
      fallbackLanguage: await _loadLanguage(fallbackLanguage, loader),
    };
    if (language != fallbackLanguage) {
      resources[language] = await _loadLanguage(language, loader);
    }
    return TrackGeekLocalizations._(resources, language);
  }

  static Future<Map<String, String>> _loadLanguage(
    String language,
    Future<String> Function(String path) read,
  ) async {
    final flat = <String, String>{};
    for (final ns in namespaces) {
      try {
        final raw = await read('assets/i18n/$language/$ns.json');
        _flatten(jsonDecode(raw) as Map<String, dynamic>, ns, flat);
      } on FlutterError {
        continue;
      } on FormatException {
        continue;
      }
    }
    return flat;
  }

  static void _flatten(
    Map<String, dynamic> json,
    String prefix,
    Map<String, String> out,
  ) {
    json.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is String) {
        out[path] = value;
      } else if (value is Map<String, dynamic>) {
        _flatten(value, path, out);
      }
    });
  }

  Future<void> setLanguage(
    String language,
    Future<String> Function(String path) read,
  ) async {
    if (!supportedLanguages.contains(language) || language == _language) return;
    _resources[language] ??= await _loadLanguage(language, read);
    _language = language;
    setNumberLocale(language);
    notifyListeners();
  }

  String t(String key, [Map<String, Object?> params = const {}]) {
    final separator = key.indexOf(':');
    final ns = separator == -1 ? 'common' : key.substring(0, separator);
    final path = separator == -1 ? key : key.substring(separator + 1);
    var lookup = path;
    final count = params['count'];
    if (count is num) {
      final suffix = count == 1 ? '_one' : '_other';
      if (_value(ns, '$path$suffix') != null) lookup = '$path$suffix';
    }
    var value = _value(ns, lookup) ?? _value('common', lookup) ?? key;
    if (count is int && !params.containsKey('formattedCount')) {
      value = value.replaceAll('{{formattedCount}}', count.humanizedCount());
    }
    params.forEach((name, param) {
      value = value.replaceAll('{{$name}}', '$param');
    });
    return value.replaceAll('<br />', '\n');
  }

  String? _value(String ns, String path) =>
      _resources[_language]?['$ns.$path'] ??
      _resources[fallbackLanguage]?['$ns.$path'];
}
