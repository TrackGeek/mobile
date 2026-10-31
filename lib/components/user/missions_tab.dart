import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/mission.dart';
import '../../services/user_service.dart';
import 'user_widgets.dart';
import '../layout/tg_refresh_indicator.dart';

const _tierOrder = ['Bronze', 'Silver', 'Gold', 'Platinum'];

class UserMissionsTab extends StatefulWidget {
  const UserMissionsTab({super.key, required this.userId, required this.users});

  final String userId;
  final UserService users;

  @override
  State<UserMissionsTab> createState() => _UserMissionsTabState();
}

class _UserMissionsTabState extends State<UserMissionsTab>
    with AutomaticKeepAliveClientMixin {
  UserMissionsSummary? _summary;
  bool _loading = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _summary = await widget.users.missions(
        widget.userId,
        language: L10nScope.read(context).language,
      );
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final summary = _summary;
    if (_loading && summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && summary == null) {
      return UserError(onRetry: _load);
    }
    if (summary == null || summary.items.isEmpty) {
      return UserEmpty(
        icon: HugeIcons.strokeRoundedTarget01,
        title: context.t('missions:empty.title'),
        description: context.t('missions:empty.description'),
      );
    }
    final byTier = <String, List<UserMission>>{};
    for (final mission in summary.items) {
      byTier.putIfAbsent(mission.tier, () => []).add(mission);
    }
    final tiers = byTier.keys.toList()
      ..sort((a, b) {
        final ai = _tierOrder.indexOf(a);
        final bi = _tierOrder.indexOf(b);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });
    return TgRefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.t('missions:description'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          UserCard(
            title: context.t('missions:title'),
            subtitle: context.t('missions:completed', {
              'completed': summary.completed,
              'total': summary.total,
            }),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: summary.total == 0
                    ? 0
                    : summary.completed / summary.total,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final tier in tiers) ...[
            Text(
              context.t('missions:tiers.$tier'),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final mission in byTier[tier]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MissionTile(mission: mission),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final UserMission mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final masked = mission.masked;
    final name = masked
        ? context.t('missions:hidden.name')
        : context.t('missions:names.${mission.key}');
    String description;
    if (mission.hidden) {
      description = context.t('missions:hidden.description');
    } else {
      final base = 'missions:descriptions.${mission.metric}';
      final specific = mission.contentType == null
          ? null
          : '${base}_${mission.contentType}';
      var value = specific == null
          ? ''
          : context.t(specific, {'count': mission.target});
      if (value.isEmpty || value == specific) {
        value = context.t(base, {'count': mission.target});
      }
      description = value == base ? '' : value;
    }
    final completedAt = mission.completedAt == null
        ? null
        : DateTime.tryParse(mission.completedAt!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: mission.isCompleted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (mission.isCompleted)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (mission.percentage / 100).clamp(0.0, 1.0),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                context.t('missions:progress', {
                  'progress': mission.progress,
                  'target': mission.target,
                }),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '${mission.percentage.round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (mission.xpReward > 0)
                Text(
                  context.t('missions:rewardXp', {'count': mission.xpReward}),
                  style: theme.textTheme.labelSmall,
                ),
              if (mission.coinReward > 0) ...[
                const SizedBox(width: 8),
                Text(
                  context.t('common:coinCount', {'count': mission.coinReward}),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ],
          ),
          if (completedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.t('missions:completedAt', {
                  'date': DateFormat.yMd(locale).format(completedAt),
                }),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
