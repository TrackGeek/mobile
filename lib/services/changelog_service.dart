import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/changelog.dart';

/// Finds the changelog entries the user hasn't seen yet and tracks the
/// last seen version in shared preferences.
class ChangelogService {
  static const _prefsKey = 'last_seen_version';

  String? _currentVersion;

  /// The changes released after the user's last seen version, or null when
  /// there is nothing to show (first install, already up to date, no entries
  /// for the delta).
  Future<List<String>?> pendingChanges({required String language}) async {
    final String current = (await PackageInfo.fromPlatform()).version;
    _currentVersion = current;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? lastSeen = prefs.getString(_prefsKey);

    // First install — nothing to show, save and move on.
    if (lastSeen == null) {
      await prefs.setString(_prefsKey, current);
      return null;
    }

    // Already up to date.
    if (lastSeen == current) return null;

    final List<String> changes = unseenChanges(
      lastSeen: lastSeen,
      current: current,
      language: language,
    );

    if (changes.isEmpty) {
      await prefs.setString(_prefsKey, current);
      return null;
    }

    return changes;
  }

  /// Marks the current version as seen. Called the moment the changelog
  /// appears.
  Future<void> markSeen() async {
    final String? version = _currentVersion;
    if (version == null) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, version);
  }
}

/// Every changelog entry with version `lastSeen < v <= current`, in the
/// requested language with 'en-US' fallback.
List<String> unseenChanges({
  required String lastSeen,
  required String current,
  required String language,
}) {
  final Version lastSeenVersion = Version.parse(lastSeen);
  final Version currentVersion = Version.parse(current);

  final List<String> result = [];

  for (final entry in kChangelog.entries) {
    final Version entryVersion = Version.parse(entry.key);

    if (entryVersion > lastSeenVersion && entryVersion <= currentVersion) {
      final changes = entry.value[language] ?? entry.value['en-US'];
      if (changes != null) result.addAll(changes);
    }
  }

  return result;
}
