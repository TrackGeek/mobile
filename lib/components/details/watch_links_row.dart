import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../models/watch_link.dart';
import '../../utils/watch_links.dart';

class CustomWatchLinks extends StatelessWidget {
  const CustomWatchLinks({
    super.key,
    required this.links,
    required this.linkContext,
    this.onManage,
  });

  final List<WatchLink> links;
  final WatchLinkContext linkContext;
  final VoidCallback? onManage;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = [
      for (final link in links)
        if (resolveWatchLinkUrl(link.url, linkContext) case final url?)
          (link: link, url: url),
    ];
    if (resolved.isEmpty && onManage == null) return const SizedBox.shrink();
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedLink01,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.t('library:watchLinks.title'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (onManage != null)
                InkWell(
                  onTap: onManage,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSettings01,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.t('library:watchLinks.manage'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (resolved.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in resolved)
                  ActionChip(
                    avatar: HugeIcon(
                      icon: HugeIcons.strokeRoundedLinkSquare02,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(entry.link.label),
                    onPressed: () => _open(entry.url),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
