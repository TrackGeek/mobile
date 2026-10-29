import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';

class StatusButtonConfig {
  const StatusButtonConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.isActive,
    this.onTap,
    this.disabled = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;
  final bool disabled;
}

class QuickStatusButtons extends StatelessWidget {
  const QuickStatusButtons({super.key, required this.buttons});

  final List<StatusButtonConfig> buttons;

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns = (constraints.maxWidth / (88 * scale)).floor().clamp(
          1,
          buttons.length,
        );
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final button in buttons)
              SizedBox(
                width: width,
                child: _StatusButton(config: button),
              ),
          ],
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.config});

  final StatusButtonConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = config.color;
    return Material(
      color: config.isActive
          ? color.withValues(alpha: 0.18)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: config.disabled ? null : config.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: config.isActive ? color : theme.colorScheme.outlineVariant,
              width: config.isActive ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: HugeIcon(icon: config.icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                config.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EpisodeProgressGrid extends StatelessWidget {
  const EpisodeProgressGrid({
    super.key,
    required this.totalEpisodes,
    required this.watchedEpisodes,
    required this.onToggle,
    this.busy = false,
  });

  final int totalEpisodes;
  final List<int> watchedEpisodes;
  final void Function(int episode) onToggle;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (totalEpisodes <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final watched = watchedEpisodes.toSet();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('library:selectWatchedEpisodes'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var episode = 1; episode <= totalEpisodes; episode++)
                _EpisodeCell(
                  episode: episode,
                  watched: watched.contains(episode),
                  onTap: busy ? null : () => onToggle(episode),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell({
    required this.episode,
    required this.watched,
    this.onTap,
  });

  final int episode;
  final bool watched;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: watched
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          border: Border.all(
            color: watched
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          '$episode',
          style: theme.textTheme.labelMedium?.copyWith(
            color: watched
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class BackfillDialog extends StatelessWidget {
  const BackfillDialog({
    super.key,
    required this.episodeCount,
    required this.loading,
    required this.onConfirm,
    required this.onDecline,
  });

  final int episodeCount;
  final bool loading;
  final void Function(bool remember) onConfirm;
  final void Function(bool remember) onDecline;

  static Future<void> show(
    BuildContext context, {
    required int episodeCount,
    required Future<void> Function(bool remember) onConfirm,
    required Future<void> Function(bool remember) onDecline,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _BackfillDialogContent(
        episodeCount: episodeCount,
        onConfirm: onConfirm,
        onDecline: onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _BackfillDialogContent extends StatefulWidget {
  const _BackfillDialogContent({
    required this.episodeCount,
    required this.onConfirm,
    required this.onDecline,
  });

  final int episodeCount;
  final Future<void> Function(bool remember) onConfirm;
  final Future<void> Function(bool remember) onDecline;

  @override
  State<_BackfillDialogContent> createState() => _BackfillDialogContentState();
}

class _BackfillDialogContentState extends State<_BackfillDialogContent> {
  bool _remember = false;
  bool _loading = false;

  Future<void> _run(Future<void> Function(bool) action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action(_remember);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCheckList, size: 24),
      title: Text(context.t('library:backfillTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('library:backfillDescription', {
              'count': widget.episodeCount,
            }),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _loading
                ? null
                : () => setState(() => _remember = !_remember),
            child: Row(
              children: [
                Checkbox(
                  value: _remember,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => _remember = v ?? false),
                ),
                Expanded(
                  child: Text(
                    context.t('library:backfillRemember'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => _run(widget.onDecline),
          child: Text(context.t('library:backfillDecline')),
        ),
        FilledButton(
          onPressed: _loading ? null : () => _run(widget.onConfirm),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.t('library:backfillConfirm')),
        ),
      ],
    );
  }
}

class TimeLeft extends StatelessWidget {
  const TimeLeft({super.key, required this.hours});

  final double? hours;

  @override
  Widget build(BuildContext context) {
    final value = hours;
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedClock01,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          '${context.t('library:timeLeft')}: '
          '${context.t('common:hourCount', {'count': value, 'formattedCount': NumberFormat('#.#', locale).format(value)})}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
