class SettingsSection {
  const SettingsSection({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.descriptionKey,
  });

  final String id;
  final String labelKey;
  final List<List<dynamic>> icon;
  final String descriptionKey;
}
