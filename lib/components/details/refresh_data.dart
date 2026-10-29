import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';

class RefreshDataCard extends StatelessWidget {
  const RefreshDataCard({
    super.key,
    required this.lastRefreshedAt,
    required this.sourceUrl,
    required this.onRefresh,
    this.pending = false,
    this.sourceName = 'MyAnimeList',
  });

  final DateTime? lastRefreshedAt;
  final String sourceUrl;
  final VoidCallback onRefresh;
  final bool pending;
  final String sourceName;

  Future<void> _openSource() async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final refreshed = lastRefreshedAt;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                context.t('library:refreshData'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            refreshed == null
                ? '-'
                : DateFormat.yMd(locale).add_Hm().format(refreshed.toLocal()),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pending ? null : onRefresh,
                  icon: pending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 14,
                        ),
                  label: Text(context.t('library:refreshData')),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _openSource,
                tooltip: sourceName,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedLink01,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
