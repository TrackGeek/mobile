import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../styles/tg_theme.dart';
import '../../models/game_detail.dart';
import '../../models/gallery_item.dart';
import '../../pages/media_gallery_page.dart';
import '../../utils/video_links.dart';
import '../media/smooth_image.dart';

class GameMediaCarousel extends StatefulWidget {
  const GameMediaCarousel({
    super.key,
    required this.game,
    required this.onOpenUrl,
  });

  final GameDetail game;
  final Future<void> Function(String url) onOpenUrl;

  @override
  State<GameMediaCarousel> createState() => _GameMediaCarouselState();
}

class _GameMediaCarouselState extends State<GameMediaCarousel> {
  final _pager = PageController();
  var _index = 0;

  int get _count => widget.game.videos.length + widget.game.screenshots.length;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: TgColors.background,
              child: PageView.builder(
                controller: _pager,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, index) {
                  if (index < widget.game.videos.length) {
                    final video = widget.game.videos[index];
                    final parsed = parseVideoUrl(video.videoId);
                    final thumb = parsed == null
                        ? ''
                        : videoThumbnailUrl(parsed) ?? '';
                    return InkWell(
                      onTap: parsed == null
                          ? null
                          : () => widget.onOpenUrl(parsed.url),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (thumb.isNotEmpty) SmoothImage(url: thumb),
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final shot = widget
                      .game
                      .screenshots[index - widget.game.videos.length];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MediaGalleryPage(
                          title: widget.game.name,
                          initialIndex: index - widget.game.videos.length,
                          items: widget.game.screenshots
                              .map((item) => GalleryItem(url: item.imageUrl))
                              .toList(),
                        ),
                      ),
                    ),
                    child: SmoothImage(
                      url: shot.imageUrl,
                      fit: BoxFit.contain,
                      error: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_count > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _count; i++)
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
