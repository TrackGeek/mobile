import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/search_item.dart';
import '../../models/media_type.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.item, this.onTap});

  final SearchItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showYear =
        item.year != null &&
        const {
          MediaType.movie,
          MediaType.anime,
          MediaType.tv,
        }.contains(item.mediaType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl != null
                      ? ImageFiltered(
                          enabled: item.isAdult,
                          imageFilter: const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          ),
                          child: Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _CoverFallback(),
                          ),
                        )
                      : const _CoverFallback(),
                  if (showYear)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _Badge(text: '${item.year}'),
                    ),
                  if (item.isAdult)
                    const Positioned(top: 4, left: 4, child: _NsfwBadge()),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 2, right: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.mediaType == null && item.subtitle != null)
                Text(
                  item.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _NsfwBadge extends StatelessWidget {
  const _NsfwBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'NSFW',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: HugeIcon(icon: HugeIcons.strokeRoundedImage01),
      ),
    );
  }
}
