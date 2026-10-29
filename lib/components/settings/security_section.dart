import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../services/auth_service.dart';
import '../../services/external_sign_in.dart';
import 'settings_card.dart';

const _minPasswordLength = 8;
const _totpLength = 6;

class SecuritySection extends StatefulWidget {
  const SecuritySection({
    super.key,
    required this.session,
    required this.auth,
    this.passkeySource,
  });

  final SessionController session;
  final AuthService auth;
  final PasskeyAssertionSource? passkeySource;

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool? _hasPassword;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await widget.auth.listAccounts();
      if (mounted) {
        setState(
          () =>
              _hasPassword = accounts.any((a) => a.providerId == 'credential'),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _hasPassword = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasswordCard(
          session: widget.session,
          auth: widget.auth,
          hasPassword: _hasPassword,
        ),
        const SizedBox(height: 16),
        PasskeysCard(auth: widget.auth, source: widget.passkeySource),
        const SizedBox(height: 16),
        TwoFactorCard(
          session: widget.session,
          auth: widget.auth,
          hasPassword: _hasPassword,
        ),
      ],
    );
  }
}

class PasswordCard extends StatefulWidget {
  const PasswordCard({
    super.key,
    required this.session,
    required this.auth,
    required this.hasPassword,
  });

  final SessionController session;
  final AuthService auth;
  final bool? hasPassword;

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _pending = false;
  bool _pendingReset = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _minError(String? value) {
    if ((value?.length ?? 0) < _minPasswordLength) {
      return context.t('settings:password.errors.min');
    }
    return null;
  }

  Future<void> _setPassword() async {
    final email = widget.session.user?.email;
    if (email == null || email.isEmpty) return;
    setState(() => _pendingReset = true);
    try {
      await widget.auth.requestPasswordReset(email);
      if (mounted) {
        showSettingsToast(context, context.t('settings:password.set.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:password.set.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingReset = false);
    }
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _pending = true);
    try {
      await widget.auth.changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      await widget.session.refresh();
      _current.clear();
      _next.clear();
      _confirm.clear();
      if (mounted) {
        showSettingsToast(
          context,
          context.t('settings:password.change.success'),
        );
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:password.change.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPassword = widget.hasPassword;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedKeyRound,
      title: context.t('common:password'),
      description: context.t('settings:password.description'),
      children: [
        if (hasPassword == false) ...[
          Text(
            context.t('settings:password.noPassword'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _pendingReset ? null : _setPassword,
              icon: _pendingReset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      size: 16,
                    ),
              label: Text(context.t('settings:password.set.button')),
            ),
          ),
        ],
        if (hasPassword == true)
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsFieldLabel(context.t('settings:password.current')),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  enabled: !_pending,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(hintText: '••••••••'),
                  validator: _minError,
                ),
                const SizedBox(height: 12),
                SettingsFieldLabel(context.t('settings:password.new')),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _next,
                  obscureText: true,
                  enabled: !_pending,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(hintText: '••••••••'),
                  validator: (value) =>
                      _minError(value) ??
                      (value == _current.text
                          ? context.t('settings:password.errors.same')
                          : null),
                ),
                const SizedBox(height: 12),
                SettingsFieldLabel(context.t('settings:password.confirm')),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  enabled: !_pending,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(hintText: '••••••••'),
                  validator: (value) =>
                      _minError(value) ??
                      (value != _next.text
                          ? context.t('settings:password.errors.mismatch')
                          : null),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _pending ? null : _changePassword,
                    icon: _pending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedKeyRound,
                            size: 16,
                          ),
                    label: Text(context.t('settings:password.change.button')),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PasskeysCard extends StatefulWidget {
  const PasskeysCard({super.key, required this.auth, this.source});

  final AuthService auth;
  final PasskeyAssertionSource? source;

  @override
  State<PasskeysCard> createState() => _PasskeysCardState();
}

class _PasskeysCardState extends State<PasskeysCard> {
  final _name = TextEditingController();
  List<PasskeyItem>? _items;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.source == null) return;
    try {
      final items = await widget.auth.listPasskeys();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      if (mounted) setState(() => _items = const []);
    }
  }

  Future<void> _add() async {
    final source = widget.source;
    if (source == null) return;
    setState(() => _pending = true);
    try {
      final name = _name.text.trim();
      final options = await widget.auth.passkeyRegisterOptions(
        name.isEmpty ? null : name,
      );
      final response = await source.register(options);
      await widget.auth.passkeyVerifyRegistration(
        response,
        name.isEmpty ? null : name,
      );
      _name.clear();
      await _load();
      if (mounted) {
        showSettingsToast(context, context.t('settings:passkeys.add.success'));
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:passkeys.add.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _delete(String id) async {
    setState(() => _pending = true);
    try {
      await widget.auth.deletePasskey(id);
      await _load();
      if (mounted) {
        showSettingsToast(
          context,
          context.t('settings:passkeys.delete.success'),
        );
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'settings:passkeys.delete.error'),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = L10nScope.of(context).language;
    final items = _items;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedFingerPrint,
      title: context.t('settings:passkeys.title'),
      description: context.t('settings:passkeys.description'),
      children: [
        if (widget.source == null)
          Text(
            context.t('settings:passkeys.unsupported'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          if (items != null && items.isEmpty)
            Text(
              context.t('settings:passkeys.empty'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (items != null)
            for (final item in items)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name?.isNotEmpty == true
                                ? item.name!
                                : context.t('settings:passkeys.unnamed'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.createdAt != null)
                            Text(
                              context.t('settings:passkeys.addedAt', {
                                'date': _formatDate(item.createdAt!, language),
                              }),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _pending ? null : () => _delete(item.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 16,
                      ),
                      label: Text(context.t('settings:passkeys.delete.button')),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          SettingsFieldLabel(context.t('settings:passkeys.nameLabel')),
          const SizedBox(height: 4),
          TextField(
            controller: _name,
            enabled: !_pending,
            decoration: InputDecoration(
              hintText: context.t('settings:passkeys.namePlaceholder'),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _pending ? null : _add,
              icon: _pending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      size: 16,
                    ),
              label: Text(context.t('settings:passkeys.add.button')),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String iso, String languageTag) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat.yMMMd(languageTag).format(parsed.toLocal());
  }
}

enum _TwoFactorPrompt { none, enable, disable, regenerate }

class TwoFactorCard extends StatefulWidget {
  const TwoFactorCard({
    super.key,
    required this.session,
    required this.auth,
    required this.hasPassword,
  });

  final SessionController session;
  final AuthService auth;
  final bool? hasPassword;

  @override
  State<TwoFactorCard> createState() => _TwoFactorCardState();
}

class _TwoFactorCardState extends State<TwoFactorCard> {
  _TwoFactorPrompt _prompt = _TwoFactorPrompt.none;
  final _password = TextEditingController();
  final _codeCtrl = TextEditingController();
  String? _totpUri;
  List<String>? _backupCodes;
  bool _pending = false;

  @override
  void dispose() {
    _password.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _enabled => widget.session.user?.twoFactorEnabled == true;

  void _reset() {
    setState(() {
      _prompt = _TwoFactorPrompt.none;
      _password.clear();
      _codeCtrl.clear();
      _totpUri = null;
      _backupCodes = null;
    });
  }

  Future<void> _confirmPassword() async {
    setState(() => _pending = true);
    try {
      switch (_prompt) {
        case _TwoFactorPrompt.enable:
          final setup = await widget.auth.twoFactorEnable(_password.text);
          setState(() {
            _password.clear();
            _totpUri = setup.totpUri;
            _backupCodes = setup.backupCodes;
          });
        case _TwoFactorPrompt.disable:
          await widget.auth.twoFactorDisable(_password.text);
          await widget.session.refresh();
          _reset();
          if (mounted) {
            showSettingsToast(
              context,
              context.t('settings:twoFactor.disable.success'),
            );
          }
        case _TwoFactorPrompt.regenerate:
          final codes = await widget.auth.twoFactorBackupCodes(_password.text);
          setState(() {
            _password.clear();
            _prompt = _TwoFactorPrompt.none;
            _backupCodes = codes;
          });
          if (mounted) {
            showSettingsToast(
              context,
              context.t('settings:twoFactor.regenerate.success'),
            );
          }
        case _TwoFactorPrompt.none:
          break;
      }
    } catch (e) {
      if (mounted) {
        final fallback = switch (_prompt) {
          _TwoFactorPrompt.enable => 'settings:twoFactor.enable.error',
          _TwoFactorPrompt.disable => 'settings:twoFactor.disable.error',
          _TwoFactorPrompt.regenerate => 'settings:twoFactor.regenerate.error',
          _TwoFactorPrompt.none => 'common:somethingWentWrong',
        };
        showSettingsToast(context, settingsErrorText(context, e, fallback));
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _verify(String code) async {
    setState(() => _pending = true);
    try {
      await widget.auth.twoFactorVerifyTotp(code);
      await widget.session.refresh();
      _reset();
      if (mounted) {
        showSettingsToast(
          context,
          context.t('settings:twoFactor.enable.success'),
        );
      }
    } catch (e) {
      setState(_codeCtrl.clear);
      if (mounted) {
        showSettingsToast(
          context,
          settingsErrorText(context, e, 'api:betterAuth.INVALID_CODE'),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  String? get _totpSecret {
    final uri = _totpUri;
    if (uri == null) return null;
    return Uri.tryParse(uri)?.queryParameters['secret'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPassword = widget.hasPassword;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final enabled = _enabled;
        return SettingsCard(
          icon: HugeIcons.strokeRoundedShieldCheck,
          title: context.t('settings:twoFactor.title'),
          description: context.t('settings:twoFactor.description'),
          titleTrailing: enabled
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.t('settings:twoFactor.active'),
                    style: theme.textTheme.labelSmall,
                  ),
                )
              : null,
          children: [
            if (hasPassword == false)
              Text(
                context.t('settings:twoFactor.noPassword'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (hasPassword == true) ...[
              if (_prompt != _TwoFactorPrompt.none && _totpUri == null) ...[
                SettingsFieldLabel(context.t('common:password')),
                const SizedBox(height: 4),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enabled: !_pending,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(hintText: '••••••••'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _pending || _password.text.isEmpty
                          ? null
                          : _confirmPassword,
                      child: _pending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(context.t('settings:twoFactor.confirm')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _pending ? null : _reset,
                      child: Text(context.t('common:cancel')),
                    ),
                  ],
                ),
              ],
              if (_totpUri != null) ...[
                Text(
                  context.t('settings:twoFactor.scanInstructions'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 184,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(data: _totpUri!, size: 160),
                ),
                if (_totpSecret != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.t('settings:twoFactor.manualEntry'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SelectableText(
                    _totpSecret!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
                if (_backupCodes != null) ...[
                  const SizedBox(height: 8),
                  _BackupCodes(codes: _backupCodes!),
                ],
                const SizedBox(height: 8),
                SettingsFieldLabel(context.t('settings:twoFactor.verifyLabel')),
                const SizedBox(height: 4),
                TextField(
                  controller: _codeCtrl,
                  enabled: !_pending,
                  keyboardType: TextInputType.number,
                  maxLength: _totpLength,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (value) {
                    if (value.length == _totpLength) _verify(value);
                  },
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _pending ? null : _reset,
                    child: Text(context.t('common:cancel')),
                  ),
                ),
              ],
              if (_prompt == _TwoFactorPrompt.none && _totpUri == null) ...[
                if (_backupCodes != null) ...[
                  _BackupCodes(codes: _backupCodes!),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (enabled) ...[
                      OutlinedButton.icon(
                        onPressed: _pending
                            ? null
                            : () => setState(
                                () => _prompt = _TwoFactorPrompt.regenerate,
                              ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 16,
                        ),
                        label: Text(
                          context.t('settings:twoFactor.regenerate.button'),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _pending
                            ? null
                            : () => setState(
                                () => _prompt = _TwoFactorPrompt.disable,
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: Colors.white,
                        ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedShieldOff,
                          size: 16,
                        ),
                        label: Text(
                          context.t('settings:twoFactor.disable.button'),
                        ),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: _pending
                            ? null
                            : () => setState(
                                () => _prompt = _TwoFactorPrompt.enable,
                              ),
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedShieldPlus,
                          size: 16,
                        ),
                        label: Text(
                          context.t('settings:twoFactor.enable.button'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _BackupCodes extends StatelessWidget {
  const _BackupCodes({required this.codes});

  final List<String> codes;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: codes.join('\n')));
    if (context.mounted) {
      showSettingsToast(
        context,
        context.t('settings:twoFactor.backupCodes.copied'),
      );
    }
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(text: codes.join('\n'), title: 'trackgeek-backup-codes.txt'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('settings:twoFactor.backupCodes.title'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('settings:twoFactor.backupCodes.warning'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              for (final code in codes)
                SizedBox(
                  width: 140,
                  child: Text(
                    code,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy(context),
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCopy01,
                  size: 16,
                ),
                label: Text(context.t('settings:twoFactor.backupCodes.copy')),
              ),
              OutlinedButton.icon(
                onPressed: _share,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 16,
                ),
                label: Text(
                  context.t('settings:twoFactor.backupCodes.download'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
