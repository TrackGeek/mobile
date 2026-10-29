import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../services/activity_service.dart';

class FeedController extends ChangeNotifier {
  FeedController(
    this._activities, {
    required this.kind,
    this.userId,
    this.language = 'en-US',
  });

  final ActivityService _activities;
  final FeedKind kind;
  final String? userId;
  final String language;

  final List<FeedEntry> entries = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  Object? error;
  bool _loaded = false;
  int _page = 0;
  int? _pages;
  final Set<String> _reacting = {};

  bool get loaded => _loaded;
  bool get hasNextPage => _pages != null && _page < _pages!;

  bool isReacting(FeedEntry entry) =>
      entry.activityId != null && _reacting.contains(entry.activityId);

  Future<void> load() async {
    if (isLoading) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _fetchPage(1);
      entries
        ..clear()
        ..addAll(page.entries);
      _page = page.inPage;
      _pages = page.pages;
      _loaded = true;
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLoaded() {
    if (_loaded || isLoading) return Future.value();
    return load();
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasNextPage) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _fetchPage(_page + 1);
      entries.addAll(page.entries);
      _page = page.inPage;
      _pages = page.pages;
    } catch (e) {
      error = e;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (isLoading) return;
    await load();
  }

  Future<void> react(
    FeedEntry entry,
    String emoji, {
    required String userId,
    required String username,
  }) async {
    final activityId = entry.activityId;
    if (activityId == null || !_reacting.add(activityId)) return;
    final index = entries.indexOf(entry);
    if (index == -1) {
      _reacting.remove(activityId);
      return;
    }
    final previous = List<FeedReaction>.from(entry.reactions);
    FeedReaction? current;
    for (final reaction in previous) {
      if (reaction.userId == userId) {
        current = reaction;
        break;
      }
    }
    entry.reactions
      ..removeWhere((r) => r.userId == userId)
      ..add(
        FeedReaction(
          id: 'pending',
          emoji: emoji,
          userId: userId,
          username: username,
        ),
      );
    if (current?.emoji == emoji) {
      entry.reactions.removeWhere((r) => r.id == 'pending');
    }
    notifyListeners();
    try {
      await _activities.toggleReaction(
        activityId: activityId,
        emoji: emoji,
        currentReaction: current,
      );
      unawaited(_reloadLoaded());
    } catch (_) {
      if (index < entries.length && identical(entries[index], entry)) {
        entry.reactions
          ..clear()
          ..addAll(previous);
        notifyListeners();
      }
      rethrow;
    } finally {
      _reacting.remove(activityId);
    }
  }

  Future<ActivityPage> _fetchPage(int page) => userId != null
      ? _activities.userActivities(userId!, page: page, language: language)
      : _activities.feed(kind, page: page, language: language);

  Future<void> _reloadLoaded() async {
    try {
      final pages = await Future.wait(
        List.generate(_page, (i) => _fetchPage(i + 1)),
      );
      entries
        ..clear()
        ..addAll([for (final p in pages) ...p.entries]);
      if (pages.isNotEmpty) _pages = pages.last.pages;
      notifyListeners();
    } on ApiException {
      // Keep optimistic state; next explicit refresh reconciles.
    }
  }
}
