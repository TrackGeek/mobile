import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/media_type.dart';
import '../../models/progress_item.dart';
import '../../services/progress_service.dart';
import '../../services/media_detail_service.dart';
import '../../pages/media_detail_page.dart';
import '../media/progress_card.dart';
import '../layout/edgy.dart';

class TrackingHeader extends StatelessWidget {
  const TrackingHeader({
    super.key,
    required this.userId,
    required this.progress,
    required this.details,
    required this.env,
    required this.onViewAll,
  });

  final String userId;
  final ProgressService progress;
  final MediaDetailService details;
  final MediaDetailEnv env;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrackingSection(
          title: context.t('library:stillWatching'),
          icon: HugeIcons.strokeRoundedTv01,
          types: const [MediaType.anime, MediaType.tv],
          statuses: const ['Watching', 'Rewatching'],
          userId: userId,
          progress: progress,
          details: details,
          env: env,
          onViewAll: onViewAll,
        ),
        _TrackingSection(
          title: context.t('library:stillReading'),
          icon: HugeIcons.strokeRoundedBookOpen01,
          types: const [MediaType.manga, MediaType.book],
          statuses: const ['Reading', 'Rereading'],
          userId: userId,
          progress: progress,
          details: details,
          env: env,
          onViewAll: onViewAll,
        ),
      ],
    );
  }
}

class _TrackingSection extends StatelessWidget {
  const _TrackingSection({
    required this.title,
    required this.icon,
    required this.types,
    required this.statuses,
    required this.userId,
    required this.progress,
    required this.details,
    required this.env,
    required this.onViewAll,
  });

  final String title;
  final List<List<dynamic>> icon;
  final List<MediaType> types;
  final List<String> statuses;
  final String userId;
  final ProgressService progress;
  final MediaDetailService details;
  final MediaDetailEnv env;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => FutureBuilder<List<ProgressItem>>(
        future:
            Future.wait(
              types.map(
                (type) => progress.activeProgress(
                  type,
                  userId: userId,
                  statuses: statuses,
                ),
              ),
            ).then(
              (groups) =>
                  [for (final group in groups) ...group].take(6).toList(),
            ),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ProgressItem>[];
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: icon,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      child: Text(context.t('common:viewAll')),
                    ),
                  ],
                ),
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const SizedBox(
                  height: 210,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.t('api:INTERNAL_SERVER_ERROR')),
                )
              else if (items.isNotEmpty)
                SizedBox(
                  height:
                      204 +
                      (MediaQuery.textScalerOf(context).scale(14) - 14) * 3,
                  child: Edgy(
                    axis: .horizontal,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => SizedBox(
                        width: 116,
                        child: ProgressCard(
                          key: ValueKey('${items[i].type}:${items[i].mediaId}'),
                          item: items[i],
                          progress: progress,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              settings: RouteSettings(
                                name: '/${items[i].type.slug}',
                              ),
                              builder: (_) => mediaDetailPage(
                                type: items[i].type,
                                id: items[i].detailId,
                                details: details,
                                env: env,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
