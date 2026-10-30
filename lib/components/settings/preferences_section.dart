import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../constants/timezones.dart';
import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../l10n/trackgeek_localizations.dart';
import '../../models/media_type.dart';
import '../../services/settings_service.dart';
import 'settings_card.dart';
import '../../utils/haptics.dart';

const _typeIcons = {
  MediaType.movie: HugeIcons.strokeRoundedClapperboard,
  MediaType.tv: HugeIcons.strokeRoundedTvMinimalPlay,
  MediaType.game: HugeIcons.strokeRoundedGameController01,
  MediaType.anime: HugeIcons.strokeRoundedMountain,
  MediaType.manga: HugeIcons.strokeRoundedLibraryBig,
  MediaType.book: HugeIcons.strokeRoundedBook01,
};

const _typeLabels = {
  MediaType.movie: 'common:types.movie_other',
  MediaType.tv: 'common:types.tv_other',
  MediaType.game: 'common:types.game_other',
  MediaType.anime: 'common:types.anime_other',
  MediaType.manga: 'common:types.manga_other',
  MediaType.book: 'common:types.book_other',
};

const _typeApiNames = {
  MediaType.movie: 'Movie',
  MediaType.tv: 'TVShow',
  MediaType.game: 'Game',
  MediaType.anime: 'Anime',
  MediaType.manga: 'Manga',
  MediaType.book: 'Book',
};

MediaType? _typeFromApi(String name) => switch (name) {
  'Movie' => MediaType.movie,
  'TVShow' => MediaType.tv,
  'Game' => MediaType.game,
  'Anime' => MediaType.anime,
  'Manga' => MediaType.manga,
  'Book' => MediaType.book,
  _ => null,
};

class PreferencesSection extends StatefulWidget {
  const PreferencesSection({
    super.key,
    required this.session,
    required this.settings,
  });

  final SessionController session;
  final SettingsService settings;

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  bool _pending = false;
  String? _language;
  String? _timezone;

  @override
  void initState() {
    super.initState();
    _language = widget.session.user?.language ?? L10nScope.of(context).language;
    _timezone = widget.session.user?.timezone;
    if (_timezone == null) _detectTimezone();
  }

  Future<void> _detectTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      if (mounted && _timezone == null) {
        setState(() => _timezone = info.identifier);
      }
    } catch (_) {}
  }

  Future<void> _patch(Map<String, Object?> fields) async {
    setState(() => _pending = true);
    try {
      await widget.settings.updateProfile(fields);
      await widget.session.refresh();
      if (mounted) {
        showSettingsToast(context, context.t('settings:save.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:save.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _setLanguage(String language) async {
    setState(() => _language = language);
    await _patch({'language': language});
    if (!mounted) return;
    final l10n = L10nScope.of(context);
    await l10n.setLanguage(language, rootBundle.loadString);
  }

  Future<void> _toggleType(MediaType type, bool enabled) async {
    final current = {
      for (final name in widget.session.user?.contentTypes ?? const [])
        ?_typeFromApi(name),
    };
    final next = enabled ? ({...current, type}) : (current..remove(type));
    if (next.isEmpty) return;
    final ordered = [
      for (final t in MediaType.values)
        if (next.contains(t)) _typeApiNames[t]!,
    ];
    await _patch({'contentTypes': ordered});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = {
      for (final name in widget.session.user?.contentTypes ?? const [])
        ?_typeFromApi(name),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: HugeIcons.strokeRoundedSettings01,
          title: context.t('settings:preferences.title'),
          description: context.t('settings:preferences.description'),
          children: [
            SettingsFieldLabel(context.t('common:language')),
            const SizedBox(height: 6),
            _SelectTile(
              value: context.t(
                'common:languages.${(_language ?? '').replaceAll('-', '')}',
              ),
              placeholder: context.t(
                'settings:preferences.language.placeholder',
              ),
              enabled: !_pending,
              onTap: () => _pickLanguage(context),
            ),
            const SizedBox(height: 16),
            SettingsFieldLabel(
              context.t('settings:preferences.timezone.title'),
            ),
            const SizedBox(height: 6),
            _SelectTile(
              value: _timezone,
              placeholder: context.t(
                'settings:preferences.timezone.placeholder',
              ),
              enabled: !_pending,
              onTap: () => _pickTimezone(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: HugeIcons.strokeRoundedLayers01,
          title: context.t('settings:contentTypes.title'),
          description: context.t('settings:contentTypes.description'),
          children: [
            for (final type in MediaType.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: _typeIcons[type]!,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(context.t(_typeLabels[type]!))),
                    Switch(
                      value: visible.contains(type),
                      onChanged:
                          _pending ||
                              (visible.contains(type) && visible.length == 1)
                          ? null
                          : (value) {
                              HapticsHelper.light();
                              _toggleType(type, value);
                            },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _pickLanguage(BuildContext context) {
    final languages = [...TrackGeekLocalizations.supportedLanguages]
      ..sort(
        (a, b) => context
            .t('common:languages.${a.replaceAll('-', '')}')
            .compareTo(context.t('common:languages.${b.replaceAll('-', '')}')),
      );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView(
          shrinkWrap: true,
          children: [
            for (final lang in languages)
              ListTile(
                title: Text(
                  context.t('common:languages.${lang.replaceAll('-', '')}'),
                ),
                trailing: lang == _language
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  HapticsHelper.selection();
                  Navigator.of(sheetContext).pop();
                  _setLanguage(lang);
                },
              ),
          ],
        );
      },
    );
  }

  void _pickTimezone(BuildContext context) {
    final groups = <String, List<String>>{
      context.t('common:continents.Africa'): Timezones.africa,
      context.t('common:continents.America'): Timezones.america,
      context.t('common:continents.Asia'): Timezones.asia,
      context.t('common:continents.Europe'): Timezones.europe,
      context.t('common:continents.Pacific'): Timezones.pacific,
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final zone in entry.value)
                    ListTile(
                      dense: true,
                      title: Text(zone),
                      trailing: zone == _timezone
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        HapticsHelper.selection();
                        Navigator.of(sheetContext).pop();
                        setState(() => _timezone = zone);
                        _patch({'timezone': zone});
                      },
                    ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.value,
    required this.placeholder,
    required this.enabled,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                overflow: TextOverflow.ellipsis,
                style: value == null
                    ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
