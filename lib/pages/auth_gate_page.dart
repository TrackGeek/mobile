import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/server_config.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import 'social_sign_in_page.dart';
import '../utils/haptics.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key, required this.session, required this.server});

  final SessionController session;
  final ServerConfig server;

  static const providers = [
    'discord',
    'github',
    'google',
    'kick',
    'microsoft',
    'notion',
    'slack',
    'spotify',
    'twitter',
  ];

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

enum _Method { password, magicLink, passkey }

class _AuthGatePageState extends State<AuthGatePage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _customUrl = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _customServer = false;
  bool _magicLinkSent = false;
  _Method _method = _Method.password;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _customUrl.dispose();
    super.dispose();
  }

  void _showError() {
    HapticsHelper.error();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.t('auth:failedToLogin'))));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final success = _register
        ? await widget.session.signUp(_name.text, _email.text, _password.text)
        : await widget.session.signIn(_email.text, _password.text);
    if (success) {
      HapticsHelper.success();
      TextInput.finishAutofillContext();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final success = await widget.session.verifyTwoFactor(_code.text);
    if (success) {
      HapticsHelper.success();
      TextInput.finishAutofillContext();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendMagicLink() async {
    setState(() => _busy = true);
    final sent = await widget.session.sendMagicLink(_email.text);
    if (mounted) {
      setState(() {
        _busy = false;
        _magicLinkSent = sent;
      });
      if (!sent) _showError();
    }
  }

  Future<void> _passkey() async {
    setState(() => _busy = true);
    final success = await widget.session.signInWithPasskey();
    if (mounted) {
      setState(() => _busy = false);
      if (!success) _showError();
    }
  }

  Future<void> _provider(String id) async {
    setState(() => _busy = true);
    try {
      if (id == 'google') {
        final ok = await widget.session.signInWithGoogle();
        if (!ok && widget.session.error != null) _showError();
        return;
      }
      final start = await widget.session.startSocialSignIn(id);
      if (!mounted) return;
      final result = await SocialSignInPage.open(
        context,
        start: start,
        apiUrl: widget.session.apiBaseUrl,
      );
      if (result == null || result.cancelled) return;
      if (result.sessionCookie != null) {
        final ok = await widget.session.completeSocialSignIn(
          result.sessionCookie!,
        );
        if (!ok) _showError();
      } else {
        _showError();
      }
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 72),
                  ),
                  Text(
                    'TrackGeek',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.t('auth:welcome.description'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  _serverSelector(context),
                  const SizedBox(height: 24),
                  if (widget.session.twoFactorPending) ...[
                    Text(
                      context.t('auth:twoFactor.title'),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(context.t('auth:twoFactor.description')),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _code,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.t('auth:twoFactor.title'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _verify,
                      child: Text(context.t('auth:twoFactor.verify')),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final id in AuthGatePage.providers)
                          IconButton(
                            key: ValueKey('auth-provider-$id'),
                            tooltip: context.t('auth:providers.$id'),
                            onPressed: _busy ? null : () => _provider(id),
                            icon: SvgPicture.asset(
                              'assets/icons/auth/$id.svg',
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.t('auth:or'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final (method, label) in [
                          (_Method.password, context.t('common:password')),
                          (_Method.magicLink, context.t('auth:magicLink')),
                          (_Method.passkey, context.t('auth:passkey')),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _method == method,
                            onSelected: (_) => setState(() => _method = method),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_method == _Method.passkey) ...[
                      Text(
                        context.t('auth:passkeyDescription'),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _passkey,
                        child: Text(context.t('auth:loginWithPasskey')),
                      ),
                    ] else ...[
                      if (_register && _method == _Method.password) ...[
                        TextField(
                          controller: _name,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.t('common:name'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _email,
                        autofillHints: [
                          _register
                              ? AutofillHints.newUsername
                              : AutofillHints.username,
                          AutofillHints.email,
                        ],
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: context.t('auth:emailAddress'),
                        ),
                      ),
                      if (_method == _Method.password) ...[
                        const SizedBox(height: 12),
                        TextField(
                          key: ValueKey(_register),
                          controller: _password,
                          autofillHints: [
                            _register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_busy) _submit();
                          },
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: context.t('app:auth.password'),
                          ),
                        ),
                      ],
                    ],
                    if (widget.session.error != null &&
                        _method != _Method.magicLink) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.t('auth:failedToLogin'),
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_method == _Method.magicLink && _magicLinkSent) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.t('auth:magicLinkSent'),
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_method == _Method.password) ...[
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(
                          context.t(_register ? 'auth:register' : 'auth:login'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _register = !_register),
                        child: Text(
                          context.t(_register ? 'auth:login' : 'auth:register'),
                        ),
                      ),
                    ],
                    if (_method == _Method.magicLink)
                      FilledButton(
                        onPressed: _busy ? null : _sendMagicLink,
                        child: Text(context.t('auth:sendMagicLink')),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _serverSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              label: Text(context.t('app:server.default')),
            ),
            ButtonSegment(
              value: true,
              label: Text(context.t('app:server.custom')),
            ),
          ],
          selected: {_customServer || !widget.server.isDefault},
          onSelectionChanged: (set) async {
            final custom = set.first;
            if (!custom) {
              await widget.server.useDefault();
            }
            setState(() => _customServer = custom);
          },
        ),
        if (_customServer || !widget.server.isDefault) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customUrl..text = widget.server.custom ?? '',
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: context.t('app:server.url'),
              hintText: 'https://',
            ),
            onSubmitted: (value) async {
              try {
                await widget.server.useCustom(value);
                setState(() {});
              } on ArgumentError {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('app:server.invalid'))),
                  );
                }
              }
            },
          ),
        ],
      ],
    );
  }
}
