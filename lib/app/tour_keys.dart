import 'package:flutter/widgets.dart';

class TourKeys {
  TourKeys._();

  static final feedTabs = GlobalKey(debugLabel: 'tour-feed-tabs');
  static final feedCompose = GlobalKey(debugLabel: 'tour-feed-compose');
  static final profileHeader = GlobalKey(debugLabel: 'tour-profile-header');
  static final profileTabs = GlobalKey(debugLabel: 'tour-profile-tabs');
  static final searchBar = GlobalKey(debugLabel: 'tour-search-bar');
  static final searchKind = GlobalKey(debugLabel: 'tour-search-kind');
  static final statusButtons = GlobalKey(debugLabel: 'tour-status-buttons');
}
