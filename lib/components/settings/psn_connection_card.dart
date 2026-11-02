import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../models/api_exception.dart';
import '../../models/psn.dart';
import '../../services/settings_service.dart';
import '../../styles/tg_theme.dart';
import '../media/smooth_image.dart';
import 'settings_card.dart';

const _npssoLength = 64;
const _playstationUrl = 'https://www.playstation.com';
const _npssoUrl = 'https://ca.account.sony.com/api/v1/ssocookie';

class PsnConnectionCard extends StatefulWidget {
  const PsnConnectionCard({super.key, required this.settings});

  final SettingsService settings;

  @override
  State<PsnConnectionCard> createState() => _PsnConnectionCardState();
}

class _PsnConnectionCardState extends State<PsnConnectionCard> {
  final _formKey = GlobalKey<FormState>();
  final _npsso = TextEditingController();
  PsnAccount? _account;
  bool _loaded = false;
  bool _error = false;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _npsso.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final account = await widget.settings.psnAccount();
      if (mounted) {
        setState(() {
          _account = account;
          _loaded = true;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  String? _npssoError(String? value) {
    if ((value?.trim().length ?? 0) != _npssoLength) {
      return context.t('settings:psn.npssoInvalid', {'count': _npssoLength});
    }
    return null;
  }

  String _errorText(Object error, String fallbackKey) {
    if (error is ApiException && error.serverCode != null) {
      final key = 'api:${error.serverCode}';
      final value = context.t(key);
      if (value != key) return value;
    }
    return settingsErrorText(context, error, fallbackKey);
  }

  Future<void> _link() async {
    if (_pending || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _pending = true);
    try {
      await widget.settings.linkPsnAccount(_npsso.text.trim());
      _npsso.clear();
      await _load();
      if (mounted) showSettingsToast(context, context.t('settings:psn.linked'));
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          _errorText(e, 'settings:connections.link.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _pending = true);
    try {
      await widget.settings.unlinkPsnAccount();
      await _load();
      if (mounted) {
        showSettingsToast(
          context,
          context.t('settings:connections.unlink.success'),
        );
      }
    } catch (e) {
      if (mounted) {
        showSettingsToast(
          context,
          _errorText(e, 'settings:connections.unlink.error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = _account;
    final showForm = _loaded && (account == null || account.expired);
    return SettingsCard(
      icon: HugeIcons.strokeRoundedGameController03,
      title: context.t('settings:psn.title'),
      description: context.t('settings:psn.description'),
      children: [
        if (!_loaded && !_error)
          Text(context.t('common:loading'), style: theme.textTheme.bodySmall),
        if (_error) SettingsFieldError(context.t('settings:psn.failed')),
        if (account != null)
          _AccountRow(account: account, pending: _pending, onUnlink: _unlink),
        if (account != null && showForm) const SizedBox(height: 16),
        if (showForm)
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Step(
                  index: 1,
                  text: context.t('settings:psn.steps.signIn'),
                  url: _playstationUrl,
                  linkLabel: 'playstation.com',
                ),
                _Step(
                  index: 2,
                  text: context.t('settings:psn.steps.openCookie'),
                  url: _npssoUrl,
                  linkLabel: _npssoUrl,
                ),
                _Step(index: 3, text: context.t('settings:psn.steps.copy')),
                const SizedBox(height: 12),
                SettingsFieldLabel(context.t('settings:psn.npssoLabel')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _npsso,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _link(),
                  validator: _npssoError,
                  enabled: !_pending,
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('settings:psn.securityNote'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _pending ? null : _link,
                    icon: _pending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const HugeIcon(
                            icon: HugeIcons.strokeRoundedLink01,
                            size: 16,
                          ),
                    label: Text(
                      account?.expired == true
                          ? context.t('settings:psn.reconnect')
                          : context.t('settings:connections.connect'),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.pending,
    required this.onUnlink,
  });

  final PsnAccount account;
  final bool pending;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = account.expired
        ? TgStatus.completed
        : theme.colorScheme.onSurfaceVariant;
    const fallback = HugeIcon(
      icon: HugeIcons.strokeRoundedGameController03,
      size: 18,
      color: TgPsn.brand,
    );
    final avatarUrl = account.avatarUrl;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: TgPsn.brand.withValues(alpha: 0.1),
            child: avatarUrl == null
                ? fallback
                : ClipOval(
                    child: SmoothImage(
                      url: avatarUrl,
                      width: 32,
                      height: 32,
                      error: fallback,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              account.onlineId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: TgRadii.chip,
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              account.expired
                  ? context.t('settings:psn.expired')
                  : context.t('settings:connections.connected'),
              style: theme.textTheme.labelSmall?.copyWith(color: badgeColor),
            ),
          ),
          IconButton(
            onPressed: pending ? null : onUnlink,
            tooltip: context.t('settings:connections.disconnect'),
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUnlink01,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.text,
    this.url,
    this.linkLabel,
  });

  final int index;
  final String text;
  final String? url;
  final String? linkLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final link = url;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$index.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                if (link != null)
                  InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        linkLabel ?? link,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
