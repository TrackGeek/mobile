import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/gallery_item.dart';
import '../../pages/media_gallery_page.dart';

class MediaCarousel extends StatefulWidget {
  const MediaCarousel({
    super.key,
    required this.title,
    this.trailerId,
    this.backdrops = const [],
    required this.onOpenUrl,
  });

  final String title;
  final String? trailerId;
  final List<String> backdrops;
  final Future<void> Function(String url) onOpenUrl;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  final _pager = PageController();
  var _index = 0;

  int get _count =>
      (widget.trailerId == null ? 0 : 1) + widget.backdrops.length;

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
              color: const Color(0xFF0A0A0A),
              child: PageView.builder(
                controller: _pager,
                itemCount: _count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, index) {
                  final trailerId = widget.trailerId;
                  if (trailerId != null && index == 0) {
                    return InkWell(
                      onTap: () => widget.onOpenUrl(
                        'https://www.youtube.com/watch?v=$trailerId',
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://i.ytimg.com/vi/$trailerId/hqdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                          const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPlay,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final backdrop =
                      widget.backdrops[index - (trailerId == null ? 0 : 1)];
                  return InkWell(
                    onTap: () => _openBackdrop(backdrop),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Transform.scale(
                            scale: 1.1,
                            child: Image.network(
                              backdrop,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        Image.network(
                          backdrop,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ],
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

  void _openBackdrop(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaGalleryPage(
          title: widget.title,
          items: widget.backdrops.map((url) => GalleryItem(url: url)).toList(),
          initialIndex: widget.backdrops.indexOf(url),
        ),
      ),
    );
  }
}
