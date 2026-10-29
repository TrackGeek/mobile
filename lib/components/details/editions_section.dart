import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/book_detail.dart';

class EditionsSection extends StatelessWidget {
  const EditionsSection({
    super.key,
    required this.editions,
    required this.title,
    required this.coverEditionId,
    required this.customCoverEditionId,
    required this.canCustomize,
    required this.busy,
    required this.onUseCover,
    required this.onResetCover,
  });

  final List<BookEdition> editions;
  final String title;
  final int? coverEditionId;
  final int? customCoverEditionId;
  final bool canCustomize;
  final bool busy;
  final ValueChanged<int> onUseCover;
  final VoidCallback onResetCover;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canCustomize && customCoverEditionId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton(
              onPressed: busy ? null : onResetCover,
              child: Text(context.t('library:useDefaultCover')),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 250).floor().clamp(1, 4);
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final edition in editions)
                  SizedBox(
                    width: width,
                    child: _EditionCard(
                      edition: edition,
                      fallbackTitle: title,
                      selected: coverEditionId == edition.id,
                      canCustomize: canCustomize,
                      busy: busy,
                      onUseCover: () => onUseCover(edition.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.edition,
    required this.fallbackTitle,
    required this.selected,
    required this.canCustomize,
    required this.busy,
    required this.onUseCover,
  });

  final BookEdition edition;
  final String fallbackTitle;
  final bool selected;
  final bool canCustomize;
  final bool busy;
  final VoidCallback onUseCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      edition.editionFormat,
      edition.language,
      edition.releaseYear?.toString(),
    ].whereType<String>().join(' · ');
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 64,
              height: 96,
              child: edition.imageUrl == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedImage01,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      edition.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedImage01,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        edition.title ?? fallbackTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (canCustomize)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: PopupMenuButton<String>(
                          tooltip: context.t('library:editionCoverOptions', {
                            'title': edition.title ?? fallbackTitle,
                          }),
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedMoreVertical,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          enabled: !busy,
                          onSelected: (_) => onUseCover(),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'cover',
                              enabled: edition.imageUrl != null,
                              child: Row(
                                children: [
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedImage01,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(context.t('library:useThisCover')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (edition.publisher != null)
                  Text(
                    edition.publisher!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                if (meta.isNotEmpty) Text(meta, style: metaStyle),
                if (edition.numberOfPages != null && edition.numberOfPages! > 0)
                  Text(
                    context.t('library:editionPageCount', {
                      'count': edition.numberOfPages!,
                    }),
                    style: metaStyle,
                  ),
                if (edition.isbn13 != null)
                  Text(
                    'ISBN 13: ${edition.isbn13}',
                    style: metaStyle,
                    softWrap: true,
                  ),
                if (edition.isbn10 != null)
                  Text(
                    'ISBN 10: ${edition.isbn10}',
                    style: metaStyle,
                    softWrap: true,
                  ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.t('library:usingThisCover'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
