import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/oauth_app.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../utils/oauth_scopes.dart';
import 'settings_card.dart';

class ConnectionsSection extends StatelessWidget {
  const ConnectionsSection({
    super.key,
    required this.settings,
    required this.auth,
  });

  final SettingsService settings;
  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthorizedAppsCard(settings: settings),
        const SizedBox(height: 16),
        DeveloperAppsCard(auth: auth),
      ],
    );
  }
}

class AuthorizedAppsCard extends StatefulWidget {
  const AuthorizedAppsCard({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<AuthorizedAppsCard> createState() => _AuthorizedAppsCardState();
}

class _AuthorizedAppsCardState extends State<AuthorizedAppsCard> {
  List<AuthorizedOAuthApp>? _apps;
  bool _error = false;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apps = await widget.settings.authorizedApps();
      if (mounted) {
        setState(() {
          _apps = apps;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _revoke(String clientId) async {
    setState(() => _pending = true);
    try {
      await widget.settings.revokeAuthorizedApp(clientId);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apps = _apps;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedAppWindow,
      title: context.t('settings:oauth.title'),
      description: context.t('settings:oauth.description'),
      children: [
        if (apps == null && !_error)
          Text(context.t('common:loading'), style: theme.textTheme.bodySmall),
        if (_error)
          Text(
            context.t('settings:oauth.failed'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (apps != null && apps.isEmpty)
          Text(
            context.t('settings:oauth.empty'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (apps != null)
          for (final app in apps)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name ?? app.clientId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final scope in app.scopes)
                          Text(
                            context.t(
                              oauthScopeLabels[scope] ??
                                  'auth:oauth.unknownScope',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _pending ? null : () => _revoke(app.clientId),
                    child: Text(context.t('settings:connections.disconnect')),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class DeveloperAppsCard extends StatefulWidget {
  const DeveloperAppsCard({super.key, required this.auth});

  final AuthService auth;

  @override
  State<DeveloperAppsCard> createState() => _DeveloperAppsCardState();
}

class _DeveloperAppsCardState extends State<DeveloperAppsCard> {
  List<OAuthClientInfo>? _clients;
  OAuthClientCredentials? _credentials;
  bool _error = false;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final clients = await widget.auth.oauthClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _create(NewOAuthClientInput input) async {
    setState(() => _pending = true);
    try {
      final credentials = await widget.auth.createOAuthClient(
        name: input.name,
        redirectUris: input.redirectUris,
        confidential: input.confidential,
        scopes: input.scopes,
      );
      setState(() => _credentials = credentials);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = true);
      rethrow;
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _delete(OAuthClientInfo client) async {
    final name = client.clientName ?? client.clientId;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.t('settings:oauth.developer.deleteTitle', {'name': name}),
        ),
        content: Text(context.t('settings:oauth.developer.deleteDescription')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.t('common:cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t('common:delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _pending = true);
    try {
      await widget.auth.deleteOAuthClient(client.clientId);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clients = _clients;
    return SettingsCard(
      icon: HugeIcons.strokeRoundedSourceCode,
      title: context.t('settings:oauth.developer.title'),
      description: context.t('settings:oauth.developer.description'),
      children: [
        if (_error)
          Text(
            context.t('settings:oauth.failed'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (_credentials != null)
          _CredentialsNotice(
            credentials: _credentials!,
            onDismiss: () => setState(() => _credentials = null),
          ),
        if (clients == null)
          Text(context.t('common:loading'), style: theme.textTheme.bodySmall)
        else
          for (final client in clients)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
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
                          client.clientName ?? client.clientId,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          client.clientId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _pending ? null : () => _delete(client),
                    child: Text(context.t('common:delete')),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        _OAuthClientForm(pending: _pending, onSubmit: _create),
      ],
    );
  }
}

class _CredentialsNotice extends StatelessWidget {
  const _CredentialsNotice({
    required this.credentials,
    required this.onDismiss,
  });

  final OAuthClientCredentials credentials;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('settings:oauth.developer.credentialsHint'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _CredentialRow(
            label: context.t('settings:oauth.developer.clientId'),
            value: credentials.clientId,
          ),
          if (credentials.clientSecret != null)
            _CredentialRow(
              label: context.t('settings:oauth.developer.clientSecret'),
              value: credentials.clientSecret!,
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onDismiss,
            child: Text(
              context.t('settings:oauth.developer.dismissCredentials'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          InkWell(
            onTap: () => Clipboard.setData(ClipboardData(text: value)),
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class NewOAuthClientInput {
  const NewOAuthClientInput({
    required this.name,
    required this.redirectUris,
    required this.confidential,
    required this.scopes,
  });

  final String name;
  final List<String> redirectUris;
  final bool confidential;
  final List<String> scopes;
}

class _OAuthClientForm extends StatefulWidget {
  const _OAuthClientForm({required this.pending, required this.onSubmit});

  final bool pending;
  final Future<void> Function(NewOAuthClientInput) onSubmit;

  @override
  State<_OAuthClientForm> createState() => _OAuthClientFormState();
}

class _OAuthClientFormState extends State<_OAuthClientForm> {
  final _name = TextEditingController();
  final _redirects = TextEditingController();
  bool _confidential = false;
  final _scopes = <String>{'profile:read', 'library:read'};
  bool _invalidRedirect = false;

  @override
  void dispose() {
    _name.dispose();
    _redirects.dispose();
    super.dispose();
  }

  bool _validUri(String uri) {
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
      return false;
    }
    if (parsed.userInfo.isNotEmpty || parsed.hasFragment) return false;
    if (parsed.scheme == 'https') return true;
    return parsed.scheme == 'http' &&
        {'localhost', '127.0.0.1', '[::1]'}.contains(parsed.host);
  }

  Future<void> _submit() async {
    final uris = _redirects.text
        .split('\n')
        .map((uri) => uri.trim())
        .where((uri) => uri.isNotEmpty)
        .toList();
    final valid = uris.isNotEmpty && uris.every(_validUri);
    setState(() => _invalidRedirect = !valid);
    if (!valid) return;
    try {
      await widget.onSubmit(
        NewOAuthClientInput(
          name: _name.text.trim(),
          redirectUris: uris,
          confidential: _confidential,
          scopes: _scopes.toList(),
        ),
      );
      _name.clear();
      _redirects.clear();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsFieldLabel(context.t('settings:oauth.developer.name')),
        const SizedBox(height: 4),
        TextField(
          controller: _name,
          enabled: !widget.pending,
          maxLength: 100,
          decoration: const InputDecoration(counterText: ''),
        ),
        const SizedBox(height: 12),
        SettingsFieldLabel(context.t('settings:oauth.developer.redirects')),
        const SizedBox(height: 4),
        TextField(
          controller: _redirects,
          enabled: !widget.pending,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            errorText: _invalidRedirect
                ? context.t('settings:oauth.developer.redirectHint')
                : null,
          ),
        ),
        if (!_invalidRedirect)
          Text(
            context.t('settings:oauth.developer.redirectHint'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _confidential,
              onChanged: widget.pending
                  ? null
                  : (value) => setState(() => _confidential = value == true),
            ),
            Expanded(
              child: Text(
                context.t('settings:oauth.developer.confidential'),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SettingsFieldLabel(context.t('settings:oauth.developer.permissions')),
        for (final scope in oauthDeveloperScopes)
          Row(
            children: [
              Checkbox(
                value: _scopes.contains(scope),
                onChanged: widget.pending
                    ? null
                    : (value) => setState(() {
                        if (value == true) {
                          _scopes.add(scope);
                        } else {
                          _scopes.remove(scope);
                        }
                      }),
              ),
              Expanded(
                child: Text(
                  context.t(
                    oauthScopeLabels[scope] ?? 'auth:oauth.unknownScope',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed:
                widget.pending || _name.text.trim().isEmpty || _scopes.isEmpty
                ? null
                : _submit,
            child: Text(
              context.t(
                widget.pending
                    ? 'common:loading'
                    : 'settings:oauth.developer.create',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
