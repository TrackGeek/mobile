import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackgeek/models/notification.dart';
import 'package:trackgeek/services/notification_alerts.dart';

import '../helpers/test_l10n.dart';

void main() {
  test('release notification keeps full message and media artwork', () async {
    final l10n = await testL10n();
    final notification = AppNotification.fromJson({
      'id': 'n1',
      'type': 'NewEpisodeReleased',
      'readAt': null,
      'createdAt': '2026-11-06T10:00:00Z',
      'releaseEvent': {
        'id': 'e1',
        'type': 'NewEpisodeReleased',
        'mediaType': 'Anime',
        'title': 'Fallback',
        'unitTitle': 'The episode title',
        'unitNumber': 3,
        'containerNumber': 2,
        'anime': {
          'id': 'a1',
          'malId': 1,
          'title': 'Anime title',
          'imageUrl': 'https://img.test/cover.jpg',
        },
      },
    });

    final details = NotificationAlerts.androidDetailsForTesting(
      notification,
      l10n,
      '/tmp/cover.jpg',
    );
    final style = details.styleInformation! as BigPictureStyleInformation;
    final picture = style.bigPicture as FilePathAndroidBitmap;

    expect(picture.data, '/tmp/cover.jpg');
    expect(style.contentTitle, 'Anime title');
    expect(
      style.summaryText,
      'Season 2, episode 3 of Anime title has released\nThe episode title',
    );
    expect(style.showBigPictureWhenCollapsed, isTrue);
  });

  test('notification without artwork expands the complete text', () async {
    final l10n = await testL10n();
    final notification = AppNotification.fromJson({
      'id': 'n1',
      'type': 'CommentOnProfile',
      'readAt': null,
      'createdAt': '2026-11-06T10:00:00Z',
      'actor': {'id': 'u1', 'name': 'Ana', 'username': 'ana'},
      'comment': {'id': 'c1', 'content': 'A complete comment'},
    });

    final details = NotificationAlerts.androidDetailsForTesting(
      notification,
      l10n,
      null,
    );
    final style = details.styleInformation! as BigTextStyleInformation;

    expect(style.bigText, '“A complete comment”');
    expect(style.contentTitle, 'ana notifications:types.CommentOnProfile');
  });
}
