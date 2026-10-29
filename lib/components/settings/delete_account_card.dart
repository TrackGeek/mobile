import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../services/auth_service.dart';
import 'settings_card.dart';

class DeleteAccountCard extends StatefulWidget {
  const DeleteAccountCard({
    super.key,
    required this.session,
    required this.auth,
  });

  final SessionController session;
  final AuthService auth;

  @override
  State<DeleteAccountCard> createState() => _DeleteAccountCardState();
}

class _DeleteAccountCardState extends State<DeleteAccountCard> {
  bool _pending = false;

  Future<void> _confirmDelete() async {
    final email = widget.session.user?.email ?? '';
    final username = widget.session.user?.username ?? '';
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_pending,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.t('settings:deleteAccount.dialog.title'),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _stripTags(
                      context.t('settings:deleteAccount.dialog.description', {
                        'email': email,
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsFieldLabel(
                    _stripTags(
                      context.t('settings:deleteAccount.dialog.confirmLabel', {
                        'username': username,
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    autocorrect: false,
                    enabled: !_pending,
                    decoration: InputDecoration(hintText: username),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _pending
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.t('common:cancel')),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      _pending ||
                          controller.text != username ||
                          username.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  icon: _pending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedMail01,
                          size: 16,
                        ),
                  label: Text(
                    context.t('settings:deleteAccount.dialog.confirm'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pending = true);
    try {
      await widget.auth.deleteUser();
      if (mounted) {
        showSettingsToast(context, context.t('settings:deleteAccount.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:deleteAccount.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  String _stripTags(String value) =>
      value.replaceAll(RegExp(r'</?[a-z]+>'), '');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsCard(
      icon: HugeIcons.strokeRoundedDelete02,
      title: context.t('settings:deleteAccount.title'),
      description: context.t('settings:deleteAccount.description'),
      borderColor: theme.colorScheme.error.withValues(alpha: 0.4),
      children: [
        Text(
          context.t('settings:deleteAccount.warning'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _confirmDelete,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 16,
            ),
            label: Text(context.t('settings:deleteAccount.title')),
          ),
        ),
      ],
    );
  }
}
