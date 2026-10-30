import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/settings/appearance_section.dart';
import '../components/settings/settings_navigation.dart';
import '../components/layout/content_frame.dart';
import '../constants/settings_sections.dart';
import '../models/settings_section.dart';
import '../styles/tg_layout.dart';
import '../components/settings/connections_section.dart';
import '../components/settings/delete_account_card.dart';
import '../components/settings/notifications_card.dart';
import '../components/settings/preferences_section.dart';
import '../components/settings/profile_form_card.dart';
import '../components/settings/security_section.dart';
import '../components/settings/watch_links_card.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../services/auth_service.dart';
import '../services/external_sign_in.dart';
import '../services/settings_service.dart';
import '../utils/haptics.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.session,
    required this.settings,
    required this.auth,
    this.passkeySource,
  });

  final SessionController session;
  final SettingsService settings;
  final AuthService auth;
  final PasskeyAssertionSource? passkeySource;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _tab = 'profile';
  final _contentKey = GlobalKey();

  void _donate() {
    launchUrl(
      Uri.parse('https://trackgeek.net/donate'),
      mode: LaunchMode.externalApplication,
    );
  }

  SettingsSection get _active => settingsSections.firstWhere(
    (s) => s.id == _tab,
    orElse: () => settingsSections[0],
  );

  void _selectSection(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                for (final group in settingsGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      context.t(group.$1),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final section in group.$2)
                    ListTile(
                      leading: HugeIcon(icon: section.icon, size: 20),
                      title: Text(context.t(section.labelKey)),
                      trailing: _tab == section.id
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        HapticsHelper.selection();
                        Navigator.of(sheetContext).pop();
                        setState(() => _tab = section.id);
                      },
                    ),
                ],
                const Divider(height: 24),
                ListTile(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    size: 20,
                  ),
                  title: Text(context.t('common:donate')),
                  trailing: const HugeIcon(
                    icon: HugeIcons.strokeRoundedLinkSquare01,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _donate();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionContent() {
    return switch (_tab) {
      'profile' => ProfileFormCard(
        session: widget.session,
        settings: widget.settings,
      ),
      'appearance' => AppearanceSection(
        session: widget.session,
        settings: widget.settings,
      ),
      'preferences' => PreferencesSection(
        session: widget.session,
        settings: widget.settings,
      ),
      'watch-links' => WatchLinksCard(settings: widget.settings),
      'notifications' => NotificationsCard(settings: widget.settings),
      'security' => SecuritySection(
        session: widget.session,
        auth: widget.auth,
        passkeySource: widget.passkeySource,
      ),
      'connections' => ConnectionsSection(
        settings: widget.settings,
        auth: widget.auth,
      ),
      'account' => DeleteAccountCard(
        session: widget.session,
        auth: widget.auth,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _active;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('common:settings'))),
      body: ContentFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            return SingleChildScrollView(
              padding: TgLayout.pagePadding(constraints.maxWidth)
                  .add(const EdgeInsets.symmetric(vertical: 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('settings:navigation.description'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 224,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final group in settingsGroups) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    4,
                                  ),
                                  child: Text(
                                    context.t(group.$1),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                for (final section in group.$2)
                                  SettingsNavItem(
                                    section: section,
                                    selected: _tab == section.id,
                                    onTap: () =>
                                        setState(() => _tab = section.id),
                                  ),
                                const SizedBox(height: 16),
                              ],
                              const Divider(height: 8),
                              SettingsNavItem(
                                section: const SettingsSection(
                                  id: 'donate',
                                  labelKey: 'common:donate',
                                  icon: HugeIcons.strokeRoundedFavourite,
                                  descriptionKey: '',
                                ),
                                selected: false,
                                trailingIcon:
                                    HugeIcons.strokeRoundedLinkSquare01,
                                onTap: _donate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: SettingsSectionBody(
                            active: active,
                            child: KeyedSubtree(
                              key: _contentKey,
                              child: _sectionContent(),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    SettingsSectionSelector(
                      label: context.t(active.labelKey),
                      hint: context.t('settings:navigation.section'),
                      onTap: () => _selectSection(context),
                    ),
                    const SizedBox(height: 16),
                    SettingsSectionBody(
                      active: active,
                      child: KeyedSubtree(
                        key: _contentKey,
                        child: _sectionContent(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
