import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../services/settings_service.dart';
import 'settings_card.dart';

const _categories = [
  'comment',
  'reaction',
  'newEpisode',
  'newChapter',
  'gameRelease',
  'sequelAdded',
  'reopenedCompleted',
  'levelUp',
  'mission',
];

class NotificationsCard extends StatefulWidget {
  const NotificationsCard({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<NotificationsCard> {
  NotificationPreferences? _preferences;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await widget.settings.notificationPreferences();
      if (mounted) setState(() => _preferences = prefs);
    } catch (_) {
      if (mounted) setState(() => _preferences = null);
    }
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _pending = true);
    try {
      final prefs = await widget.settings.updateNotificationPreferences({
        key: value,
      });
      if (mounted) setState(() => _preferences = prefs);
    } catch (_) {
      if (mounted) {
        showSettingsToast(context, context.t('common:somethingWentWrong'));
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = _preferences;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedSlidersHorizontal,
      title: context.t('notifications:preferences.title'),
      description: context.t('notifications:preferences.description'),
      children: [
        for (final key in _categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('notifications:preferences.$key'),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        context.t(
                          'notifications:preferences.${key}Description',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (prefs == null)
                  const SizedBox(
                    width: 32,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: prefs[key],
                    onChanged: _pending ? null : (value) => _toggle(key, value),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
