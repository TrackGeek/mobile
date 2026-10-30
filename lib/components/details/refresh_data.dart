import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../utils/dates.dart';

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

  Future<void> _confirm(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('library:refreshDataModal.title')),
        content: Text(context.t('library:refreshDataModal.description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t('common:cancel')),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openSource();
            },
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedLink01, size: 16),
            label: Text(context.t('library:refreshDataModal.checkSource')),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onRefresh();
            },
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 16,
            ),
            label: Text(
              context.t('library:refreshDataModal.refreshInfoButton'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refreshed = lastRefreshedAt;
    final relative = refreshed == null
        ? null
        : formatRelativeTime(refreshed, context.t);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: pending ? null : () => _confirm(context),
        icon: pending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 14),
        label: Text(
          relative == null
              ? context.t('library:refreshData')
              : '${context.t('library:refreshData')} • $relative',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
