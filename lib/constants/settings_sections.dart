import 'package:hugeicons/hugeicons.dart';

import '../models/settings_section.dart';

const settingsSections = [
  SettingsSection(
    id: 'profile',
    labelKey: 'common:profile',
    icon: HugeIcons.strokeRoundedUser,
    descriptionKey: 'settings:navigation.descriptions.profile',
  ),
  SettingsSection(
    id: 'appearance',
    labelKey: 'settings:tabs.appearance',
    icon: HugeIcons.strokeRoundedPalette,
    descriptionKey: 'settings:navigation.descriptions.appearance',
  ),
  SettingsSection(
    id: 'preferences',
    labelKey: 'settings:tabs.preferences',
    icon: HugeIcons.strokeRoundedSlidersHorizontal,
    descriptionKey: 'settings:navigation.descriptions.preferences',
  ),
  SettingsSection(
    id: 'watch-links',
    labelKey: 'settings:watchLinks.title',
    icon: HugeIcons.strokeRoundedLinkSquare01,
    descriptionKey: 'settings:navigation.descriptions.watchLinks',
  ),
  SettingsSection(
    id: 'notifications',
    labelKey: 'common:notifications',
    icon: HugeIcons.strokeRoundedBell,
    descriptionKey: 'notifications:preferences.description',
  ),
  SettingsSection(
    id: 'security',
    labelKey: 'settings:tabs.security',
    icon: HugeIcons.strokeRoundedShieldCheck,
    descriptionKey: 'settings:navigation.descriptions.security',
  ),
  SettingsSection(
    id: 'connections',
    labelKey: 'settings:tabs.connections',
    icon: HugeIcons.strokeRoundedLink01,
    descriptionKey: 'settings:connections.description',
  ),
  SettingsSection(
    id: 'account',
    labelKey: 'settings:tabs.account',
    icon: HugeIcons.strokeRoundedUserCog,
    descriptionKey: 'settings:deleteAccount.description',
  ),
];

final settingsGroups = [
  (
    'settings:navigation.groups.personal',
    [settingsSections[0], settingsSections[1]],
  ),
  (
    'settings:navigation.groups.application',
    [settingsSections[2], settingsSections[3], settingsSections[4]],
  ),
  (
    'settings:navigation.groups.account',
    [settingsSections[5], settingsSections[6], settingsSections[7]],
  ),
];
