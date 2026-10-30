import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/anime_detail.dart';

const _relationLabelKeys = {
  'sequel': 'sequel',
  'prequel': 'prequel',
  'side story': 'sideStory',
  'parent story': 'parent',
  'alternative version': 'alternative',
  'alternative setting': 'alternative',
  'spin-off': 'spinOff',
  'adaptation': 'adaptation',
  'summary': 'summary',
  'character': 'character',
  'full story': 'fullStory',
  'other': 'other',
};

const _malPlaceholder =
    'https://cdn.myanimelist.net/images/questionmark_23.gif';

String? malImage(String? url) =>
    url != null && url.startsWith(_malPlaceholder) ? null : url;

class RelationNode {
  const RelationNode({
    required this.id,
    required this.title,
    required this.label,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String label;
  final String? imageUrl;
}

List<RelationNode> buildAnimeRelationNodes(
  List<AnimeRelation> relations,
  String Function(String key) labelFor,
) {
  final seen = <int>{};
  final nodes = <RelationNode>[];
  for (final relation in relations) {
    final key = _relationLabelKeys[relation.relationType.toLowerCase()];
    final label = key != null ? labelFor(key) : relation.relationType;
    for (final entry in relation.entry) {
      if (entry.type != 'anime' || !seen.add(entry.malId)) continue;
      nodes.add(
        RelationNode(
          id: entry.malId,
          title: entry.title,
          label: label,
          imageUrl: malImage(entry.imageUrl),
        ),
      );
    }
  }
  return nodes;
}

class RelationsView extends StatelessWidget {
  const RelationsView({
    super.key,
    required this.rootTitle,
    this.rootImageUrl,
    required this.nodes,
    this.onOpen,
  });

  final String rootTitle;
  final String? rootImageUrl;
  final List<RelationNode> nodes;
  final void Function(int id)? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<RelationNode>>{};
    for (final node in nodes) {
      groups.putIfAbsent(node.label, () => []).add(node);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Cover(url: malImage(rootImageUrl), size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rootTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final group in groups.entries) ...[
            const SizedBox(height: 14),
            Text(
              group.key,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 126 + MediaQuery.textScalerOf(context).scale(11) * 3,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.value.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final node = group.value[index];
                  return SizedBox(
                    width: 88,
                    child: InkWell(
                      onTap: onOpen == null ? null : () => onOpen!(node.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          _Cover(url: node.imageUrl, size: 80),
                          const SizedBox(height: 6),
                          Text(
                            node.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? Container(
              width: size,
              height: size * 1.4,
              color: theme.colorScheme.surface,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Image.network(
              url!,
              width: size,
              height: size * 1.4,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: size,
                height: size * 1.4,
                color: theme.colorScheme.surface,
              ),
            ),
    );
  }
}
