import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/media/zoomable_image.dart';
import '../l10n/l10n_context.dart';
import '../models/gallery_item.dart';
import '../utils/video_links.dart';

class MediaGalleryPage extends StatefulWidget {
  const MediaGalleryPage({
    super.key,
    required this.title,
    required this.items,
    this.initialIndex = 0,
    this.externalVideo = true,
  });

  final String title;
  final List<GalleryItem> items;
  final int initialIndex;
  final bool externalVideo;

  @override
  State<MediaGalleryPage> createState() => _MediaGalleryPageState();
}

class _MediaGalleryPageState extends State<MediaGalleryPage> {
  late final PageController _pager;
  late int _index;
  bool _interacting = false;

  @override
  void initState() {
    super.initState();
    _index = widget.items.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.items.length - 1);
    _pager = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final target = _index + delta;
    if (_interacting || target < 0 || target >= widget.items.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pager.jumpToPage(target);
    } else {
      _pager.animateToPage(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items.isEmpty ? null : widget.items[_index];
    final video = item?.videoUrl == null
        ? null
        : parseVideoUrl(item!.videoUrl!);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(
              item?.title ?? widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    widget.items.isEmpty
                        ? '0 / 0'
                        : '${_index + 1} / ${widget.items.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pager,
                    physics: _interacting
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: widget.items.length,
                    onPageChanged: (index) => setState(() {
                      _index = index;
                      _interacting = false;
                    }),
                    itemBuilder: (context, index) => ZoomableImage(
                      key: ValueKey('gallery-image-$index'),
                      url: widget.items[index].url,
                      label: widget.items[index].title ?? widget.title,
                      onInteractionChanged: (value) {
                        if (index == _index && value != _interacting) {
                          setState(() => _interacting = value);
                        }
                      },
                    ),
                  ),
                ),
                if (item?.description?.isNotEmpty == true)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 720,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.2,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Text(
                        item!.description!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: context.t('common:previous'),
                      onPressed: _index > 0 && !_interacting
                          ? () => _move(-1)
                          : null,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: Colors.white70,
                      ),
                    ),
                    if (video != null)
                      Flexible(
                        child: FilledButton.icon(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            size: 18,
                          ),
                          label: Text(video.provider),
                          onPressed: () => launchUrl(
                            Uri.parse(video.url),
                            mode: widget.externalVideo
                                ? LaunchMode.externalApplication
                                : LaunchMode.platformDefault,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: context.t('common:next'),
                      onPressed:
                          _index < widget.items.length - 1 && !_interacting
                          ? () => _move(1)
                          : null,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
