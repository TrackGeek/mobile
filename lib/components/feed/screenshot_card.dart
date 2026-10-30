import 'dart:ui';

import 'package:flutter/material.dart';

import '../../styles/tg_theme.dart';
import '../../models/gallery_item.dart';
import '../../pages/media_gallery_page.dart';

import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../utils/video_links.dart';
import 'feed_item_card.dart';
import 'feed_reactions.dart';
import 'feed_title.dart';

const _previewLimit = 4;

class ScreenshotCard extends StatefulWidget {
  const ScreenshotCard({
    super.key,
    required this.entry,
    required this.currentUserId,
    this.onMediaTap,
    this.onUserTap,
    this.onTitleLinkTap,
    this.onReact,
    this.isReacting = false,
  });

  final FeedEntry entry;
  final String currentUserId;
  final VoidCallback? onMediaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onTitleLinkTap;
  final void Function(String emoji, FeedReaction? currentReaction)? onReact;
  final bool isReacting;

  @override
  State<ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<ScreenshotCard> {
  final Set<String> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final locale = L10nScope.of(context).language;
    final previews = entry.screenshots.take(_previewLimit).toList();
    final remaining = entry.screenshots.length - previews.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FeedTitle(
                    titleKey: entry.titleKey,
                    values: entry.titleValues,
                    onLinkTap: widget.onTitleLinkTap,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMd(locale).add_jm().format(entry.time.toLocal()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              children: [
                for (var row = 0; row < _rows(previews.length); row++)
                  Row(
                    children: [
                      for (
                        var i = _rowStart(row, previews.length);
                        i < _rowEnd(row, previews.length);
                        i++
                      )
                        Expanded(
                          child: _ScreenshotTile(
                            screenshot: previews[i],
                            title: entry.mediaTitle ?? '',
                            revealed:
                                !previews[i].isSpoiler ||
                                _revealed.contains(previews[i].id),
                            overlayCount:
                                i == previews.length - 1 && remaining > 0
                                ? remaining
                                : 0,
                            onReveal: () =>
                                setState(() => _revealed.add(previews[i].id)),
                            onOpen: () => _openGallery(i),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onUserTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FeedAvatar(
                        name: entry.profile.name,
                        avatarUrl: entry.profile.avatarUrl,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.profile.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FeedReactions(
                  currentUserId: widget.currentUserId,
                  activityId: entry.activityId,
                  reactions: entry.reactions,
                  likes: entry.likes,
                  onReact: widget.onReact,
                  isReacting: widget.isReacting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _rows(int count) => switch (count) {
    0 => 0,
    1 => 1,
    _ => (count / 2).ceil(),
  };

  int _rowStart(int row, int count) {
    if (count == 3) return row == 0 ? 0 : 1;
    return row * 2;
  }

  int _rowEnd(int row, int count) {
    if (count == 3) return row == 0 ? 1 : 3;
    return (row * 2 + 2).clamp(0, count);
  }

  void _openGallery(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(
          items: widget.entry.screenshots.map((shot) {
            final video = shot.type == 'Video' ? parseVideoUrl(shot.url) : null;
            return GalleryItem(
              url: video == null ? shot.url : videoThumbnailUrl(video) ?? '',
              description: shot.description,
              videoUrl: video?.url,
            );
          }).toList(),
          externalVideo: false,
          title: widget.entry.mediaTitle ?? '',
          initialIndex: index,
        ),
      ),
    );
  }
}

class _ScreenshotTile extends StatelessWidget {
  const _ScreenshotTile({
    required this.screenshot,
    required this.title,
    required this.revealed,
    required this.overlayCount,
    required this.onReveal,
    required this.onOpen,
  });

  final FeedScreenshot screenshot;
  final String title;
  final bool revealed;
  final int overlayCount;
  final VoidCallback onReveal;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final video = screenshot.type == 'Video'
        ? parseVideoUrl(screenshot.url)
        : null;
    final source = video != null
        ? videoThumbnailUrl(video) ?? ''
        : screenshot.url;
    return InkWell(
      onTap: revealed ? onOpen : onReveal,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: TgColors.background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (source.isNotEmpty)
                ImageFiltered(
                  enabled: !revealed,
                  imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Image.network(
                    source,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                )
              else
                Center(
                  child: HugeIcon(
                    icon: video != null
                        ? HugeIcons.strokeRoundedVideoReplay
                        : HugeIcons.strokeRoundedImage01,
                    size: 40,
                    color: Colors.white70,
                  ),
                ),
              if (!revealed)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedEyeOff,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.t('comments:spoilerReveal'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (revealed && video != null)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlay,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (revealed && overlayCount > 0)
                Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Text(
                      '+$overlayCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
