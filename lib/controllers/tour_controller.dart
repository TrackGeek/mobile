import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

enum TourStage { welcome, feed, profile, search, details, done }

class TourController extends ChangeNotifier {
  TourController._();

  static final instance = TourController._();

  static const _prefsKey = 'tour_stage';
  static const newAccountWindow = Duration(days: 3);

  TourStage? _stage;
  bool _restored = false;

  TourStage? get stage => _stage;

  Future<void> restore() async {
    if (_restored) return;
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    _stage = TourStage.values.where((s) => s.name == name).firstOrNull;
    _restored = true;
  }

  Future<void> startIfNew(SessionUser? user, {DateTime? now}) async {
    await restore();
    final createdAt = user?.createdAt;
    if (_stage != null || createdAt == null) return;
    if ((now ?? DateTime.now()).difference(createdAt) >= newAccountWindow) {
      return;
    }
    await go(TourStage.welcome);
  }

  Future<void> start() => go(TourStage.welcome);

  Future<void> finish() => go(TourStage.done);

  Future<void> go(TourStage stage) async {
    _stage = stage;
    _restored = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, stage.name);
  }
}
