import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/api_exception.dart';
import '../../models/psn.dart';
import '../../services/user_service.dart';
import '../../styles/tg_theme.dart';
import '../../utils/dates.dart';
import '../../utils/haptics.dart';
import '../../utils/numbers.dart';
import '../media/smooth_image.dart';
import 'user_widgets.dart';

const _completedProgress = 100;

const _gradeColors = {
  PsnTrophyGrade.platinum: TgPsn.platinum,
  PsnTrophyGrade.gold: TgPsn.gold,
  PsnTrophyGrade.silver: TgPsn.silver,
  PsnTrophyGrade.bronze: TgPsn.bronze,
};

const _gradeLabels = {
  PsnTrophyGrade.platinum: 'missions:tiers.Platinum',
  PsnTrophyGrade.gold: 'missions:tiers.Gold',
  PsnTrophyGrade.silver: 'missions:tiers.Silver',
  PsnTrophyGrade.bronze: 'missions:tiers.Bronze',
};

const _tabular = [FontFeature.tabularFigures()];

class PsnTrophiesCard extends StatefulWidget {
  const PsnTrophiesCard({
    super.key,
    required this.userId,
    required this.isOwner,
    required this.users,
    this.onOpenSettings,
  });

  final String userId;
  final bool isOwner;
  final UserService users;
  final VoidCallback? onOpenSettings;

  @override
  State<PsnTrophiesCard> createState() => _PsnTrophiesCardState();
}

class _PsnTrophiesCardState extends State<PsnTrophiesCard> {
  PsnTrophies? _trophies;
  bool _loaded = false;
  bool _failed = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trophies = await widget.users.psnTrophies(
        widget.userId,
        language: L10nScope.read(context).language,
      );
      if (mounted) {
        setState(() {
          _trophies = trophies;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _failed = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final trophies = await widget.users.refreshPsnTrophies();
      if (!mounted) return;
      setState(() => _trophies = trophies);
      _toast(context.t('user:psnRefreshed'));
    } catch (error) {
      if (mounted) _toast(_errorText(error), error: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String _errorText(Object error) {
    if (error is ApiException && error.serverCode != null) {
      final key = 'api:${error.serverCode}';
      final value = context.t(key);
      if (value != key) return value;
    }
    return context.t('api:INTERNAL_SERVER_ERROR');
  }

  void _toast(String message, {bool error = false}) {
    error ? HapticsHelper.error() : HapticsHelper.success();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final trophies = _trophies;
    final summary = trophies?.summary;
    final profile = trophies?.profile;
    if (_loaded && summary == null && !widget.isOwner) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UserCard(
        title: context.t('user:psnTrophies'),
        icon: HugeIcons.strokeRoundedGameController03,
        trailing: widget.isOwner && summary != null
            ? _RefreshButton(pending: _refreshing, onPressed: _refresh)
            : null,
        child: !_loaded
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            : summary != null && profile != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryBand(profile: profile, summary: summary),
                  if (trophies!.recentTitles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _RecentTitles(titles: trophies.recentTitles),
                  ],
                  if (trophies.updatedAt != null) ...[
                    const SizedBox(height: 12),
                    _UpdatedAt(updatedAt: trophies.updatedAt!),
                  ],
                ],
              )
            : _EmptyState(
                trophies: trophies,
                failed: _failed,
                onOpenSettings: widget.onOpenSettings,
              ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.pending, required this.onPressed});

  final bool pending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: pending ? null : onPressed,
      tooltip: context.t('user:psnRefresh'),
      visualDensity: VisualDensity.compact,
      icon: pending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.profile, required this.summary});

  final PsnProfile profile;
  final PsnTrophySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: TgRadii.card,
        border: Border.all(color: TgPsn.brand.withValues(alpha: 0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TgPsn.brand.withValues(alpha: 0.15),
            TgPsn.brand.withValues(alpha: 0),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(profile: profile),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            profile.onlineId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.t('xp:levelShort', {'level': summary.level}),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: summary.progress / 100,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t('user:psnNextLevel', {
                        'progress': '${summary.progress}%',
                        'level': summary.level + 1,
                      }),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final grade in PsnTrophyGrade.values)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedTrophy,
                            size: 16,
                            color: _gradeColors[grade]!,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              summary.earnedTrophies.of(grade).humanizedCount(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: _tabular,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t(_gradeLabels[grade]!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final PsnProfile profile;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final fallback = HugeIcon(
      icon: HugeIcons.strokeRoundedGameController03,
      size: 22,
      color: TgPsn.brand,
    );
    final avatarUrl = profile.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TgPsn.brand.withValues(alpha: 0.4), width: 2),
      ),
      child: CircleAvatar(
        radius: _size / 2,
        backgroundColor: TgPsn.brand.withValues(alpha: 0.1),
        child: avatarUrl == null
            ? fallback
            : ClipOval(
                child: SmoothImage(
                  url: avatarUrl,
                  width: _size,
                  height: _size,
                  error: fallback,
                ),
              ),
      ),
    );
  }
}

class _RecentTitles extends StatelessWidget {
  const _RecentTitles({required this.titles});

  final List<PsnTrophyTitle> titles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.t('user:psnRecentGames'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (final (index, title) in titles.indexed) ...[
          if (index > 0)
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
          _TitleRow(title: title),
        ],
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.title});

  final PsnTrophyTitle title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final completed = title.progress >= _completedProgress;
    final earnedGrades = [
      for (final grade in PsnTrophyGrade.values)
        if (title.earnedTrophies.of(grade) > 0) grade,
    ];
    final fallback = Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedGameController03,
        size: 20,
        color: muted,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 46,
              color: theme.colorScheme.surfaceContainerHighest,
              child: title.iconUrl.isEmpty
                  ? fallback
                  : SmoothImage(
                      url: title.iconUrl,
                      fit: BoxFit.contain,
                      width: 80,
                      height: 46,
                      error: fallback,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final platform in title.platforms)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          platform,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    for (final grade in earnedGrades)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedTrophy,
                            size: 13,
                            color: _gradeColors[grade]!,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            title.earnedTrophies.of(grade).humanizedCount(),
                            semanticsLabel:
                                '${title.earnedTrophies.of(grade)} ${context.t(_gradeLabels[grade]!)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontFeatures: _tabular,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${title.progress}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: _tabular,
                    color: completed ? TgPsn.platinum : null,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: title.progress / 100,
                    minHeight: 5,
                    color: completed ? TgPsn.platinum : null,
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

class _UpdatedAt extends StatelessWidget {
  const _UpdatedAt({required this.updatedAt});

  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.t('user:psnUpdatedAt', {
        'time': formatRelativeTime(updatedAt, context.t),
      }),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.trophies,
    required this.failed,
    this.onOpenSettings,
  });

  final PsnTrophies? trophies;
  final bool failed;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = failed
        ? 'Unavailable'
        : trophies?.linked != true
        ? 'NotLinked'
        : trophies!.expired
        ? 'Expired'
        : 'Unavailable';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: TgRadii.card,
        border: Border.all(color: TgPsn.brand.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TgPsn.brand.withValues(alpha: 0.1),
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedGameController03,
              size: 24,
              color: TgPsn.brand,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.t('user:psn$state'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            context.t('user:psn${state}Description'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (state != 'Unavailable' && onOpenSettings != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onOpenSettings,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedLink01,
                size: 16,
              ),
              label: Text(context.t('settings:connections.connect')),
            ),
          ],
        ],
      ),
    );
  }
}
