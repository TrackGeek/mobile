import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../services/settings_service.dart';
import 'settings_card.dart';

const _aboutMaxLength = 500;
final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');

class ProfileFormCard extends StatefulWidget {
  const ProfileFormCard({
    super.key,
    required this.session,
    required this.settings,
  });

  final SessionController session;
  final SettingsService settings;

  @override
  State<ProfileFormCard> createState() => _ProfileFormCardState();
}

class _ProfileFormCardState extends State<ProfileFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _about = TextEditingController();
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _sync();
    widget.session.addListener(_sync);
  }

  @override
  void dispose() {
    widget.session.removeListener(_sync);
    _name.dispose();
    _username.dispose();
    _about.dispose();
    super.dispose();
  }

  void _sync() {
    final user = widget.session.user;
    if (user == null || !mounted) return;
    if (_name.text != user.name) _name.text = user.name;
    if (_username.text != (user.username ?? '')) {
      _username.text = user.username ?? '';
    }
    if (_about.text != (user.about ?? '')) _about.text = user.about ?? '';
  }

  String? _nameError(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return context.t('settings:profile.errors.nameMin');
    if (v.length > 50) return context.t('settings:profile.errors.nameMax');
    return null;
  }

  String? _usernameError(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return context.t('settings:profile.errors.usernameMin');
    if (v.length > 30) return context.t('settings:profile.errors.usernameMax');
    if (!_usernameRegex.hasMatch(v)) {
      return context.t('settings:profile.errors.usernameFormat');
    }
    return null;
  }

  String? _aboutError(String? value) {
    if ((value?.trim().length ?? 0) > _aboutMaxLength) {
      return context.t('settings:profile.errors.aboutMax');
    }
    return null;
  }

  Future<void> _submit() async {
    if (_pending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _pending = true);
    try {
      await Future.wait([
        widget.settings.updateUser(
          name: _name.text.trim(),
          username: _username.text.trim(),
        ),
        widget.settings.updateProfile({'about': _about.text.trim()}),
      ]);
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

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      icon: HugeIcons.strokeRoundedUser,
      title: context.t('settings:profile.title'),
      description: context.t('settings:profile.description'),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsFieldLabel(context.t('common:name')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(hintText: 'Jhon Doe'),
                validator: _nameError,
                enabled: !_pending,
              ),
              const SizedBox(height: 16),
              SettingsFieldLabel(context.t('settings:profile.username')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  hintText: 'jhondoe',
                  prefixText: '@',
                ),
                validator: _usernameError,
                enabled: !_pending,
              ),
              const SizedBox(height: 16),
              SettingsFieldLabel(context.t('settings:profile.about')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _about,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                ),
                minLines: 4,
                maxLines: 8,
                maxLength: _aboutMaxLength,
                validator: _aboutError,
                enabled: !_pending,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _pending ? null : _submit,
                  icon: _pending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                          size: 16,
                        ),
                  label: Text(context.t('common:saveChanges')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
