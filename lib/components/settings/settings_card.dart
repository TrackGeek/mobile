import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/api_exception.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.children,
    this.borderColor,
    this.titleTrailing,
  });

  final dynamic icon;
  final String title;
  final String? description;
  final List<Widget> children;
  final Color? borderColor;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HugeIcon(
                  icon: icon,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                ?titleTrailing,
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class SettingsFieldLabel extends StatelessWidget {
  const SettingsFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class SettingsFieldError extends StatelessWidget {
  const SettingsFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }
}

void showSettingsToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String settingsErrorText(
  BuildContext context,
  Object error,
  String fallbackKey,
) {
  if (error is ApiException && error.serverCode != null) {
    final key = 'api:betterAuth.${error.serverCode}';
    final value = context.t(key);
    if (value != key) return value;
  }
  return context.t(fallbackKey);
}
