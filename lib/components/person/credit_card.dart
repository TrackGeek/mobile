import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/person.dart';

const _mediaIcons = {
  MediaType.movie: HugeIcons.strokeRoundedClapperboard,
  MediaType.tv: HugeIcons.strokeRoundedTv01,
  MediaType.anime: HugeIcons.strokeRoundedSparkles,
  MediaType.manga: HugeIcons.strokeRoundedLibraryBig,
};

class CreditCard extends StatelessWidget {
  const CreditCard({super.key, required this.credit, this.onTap});

  final PersonCredit credit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = credit.roles.where((role) => role.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(credit: credit),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _MediaBadge(
                      icon: _mediaIcons[credit.mediaType]!,
                      year: credit.year,
                    ),
                  ),
                  if (credit.episodeCount != null && credit.episodeCount! > 1)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _Badge(
                        text: context.t('library:episodeCount', {
                          'count': credit.episodeCount,
                        }),
                      ),
                    ),
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
                credit.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (roles.isNotEmpty)
                Text(
                  roles,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.credit});

  final PersonCredit credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = credit.imageUrl;
    final child = imageUrl == null
        ? Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: Icon(Icons.image_not_supported_outlined),
            ),
          )
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          );
    if (!credit.isAdult) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon, this.year});

  final List<List<dynamic>> icon;
  final int? year;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 12, color: Colors.white),
          if (year != null) ...[
            const SizedBox(width: 4),
            Text(
              '$year',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
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
        color: Colors.black.withValues(alpha: 0.65),
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
