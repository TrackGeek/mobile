import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/progress_item.dart';
import '../../services/progress_service.dart';
import 'smooth_image.dart';
import '../../utils/haptics.dart';

class ProgressCard extends StatefulWidget {
  const ProgressCard({
    super.key,
    required this.item,
    required this.progress,
    required this.onTap,
  });

  final ProgressItem item;
  final ProgressService progress;
  final VoidCallback onTap;

  @override
  State<ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<ProgressCard> {
  bool _busy = false;

  Future<void> _increment() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.progress.increment(widget.item);
    } catch (_) {
      if (mounted) {
        HapticsHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('api:INTERNAL_SERVER_ERROR'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final episodes = item.type == MediaType.anime || item.type == MediaType.tv;
    final active = episodes
        ? const ['Watching', 'Rewatching'].contains(item.status)
        : const ['Reading', 'Rereading'].contains(item.status);
    final label = context.t(
      episodes
          ? 'library:markNextEpisodeWatched'
          : 'library:incrementReadingProgress',
    );
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: item.imageUrl == null
                        ? const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedImage01,
                            ),
                          )
                        : ImageFiltered(
                            enabled: item.isAdult,
                            imageFilter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: SmoothImage(
                              url: item.imageUrl!,
                              error: const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImage01,
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (item.year != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _CoverLabel(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text('${item.year}'),
                        ),
                      ),
                    ),
                  if (item.current != null)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _CoverLabel(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    '${item.current}/${item.total ?? '?'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (active)
                                GestureDetector(
                                  onTap: () {},
                                  child: IconButton(
                                    tooltip: label,
                                    onPressed: !_busy && item.canIncrement
                                        ? _increment
                                        : null,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    style: IconButton.styleFrom(
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: const Size(24, 24),
                                      maximumSize: const Size(24, 24),
                                    ),
                                    padding: EdgeInsets.only(right: 4),
                                    color: Colors.white,
                                    disabledColor: Colors.white54,
                                    icon: _busy
                                        ? const SizedBox.square(
                                            dimension: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const HugeIcon(
                                            icon: HugeIcons.strokeRoundedAdd01,
                                            size: 16,
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CoverLabel extends StatelessWidget {
  const _CoverLabel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.labelSmall!
            .copyWith(color: Colors.white),
        child: child,
      ),
    );
  }
}
