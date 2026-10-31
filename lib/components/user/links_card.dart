import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import 'user_widgets.dart';
import '../../utils/adaptive_sheet_route.dart';
import '../../utils/social_links.dart';

const _knownHosts = {
  'github.com': 'GitHub',
  'gitlab.com': 'GitLab',
  'x.com': 'X',
  'twitter.com': 'X',
  'instagram.com': 'Instagram',
  'youtube.com': 'YouTube',
  'youtu.be': 'YouTube',
  'twitch.tv': 'Twitch',
  'kick.com': 'Kick',
  'tiktok.com': 'TikTok',
  'discord.gg': 'Discord',
  'discord.com': 'Discord',
  'linkedin.com': 'LinkedIn',
  'reddit.com': 'Reddit',
  'steamcommunity.com': 'Steam',
  'myanimelist.net': 'MyAnimeList',
  'anilist.co': 'AniList',
  'letterboxd.com': 'Letterboxd',
  'open.spotify.com': 'Spotify',
  'spotify.com': 'Spotify',
  'bsky.app': 'Bluesky',
  'threads.net': 'Threads',
  'threads.com': 'Threads',
  't.me': 'Telegram',
  'telegram.me': 'Telegram',
  'mastodon.social': 'Mastodon',
  'behance.net': 'Behance',
  'dribbble.com': 'Dribbble',
  'medium.com': 'Medium',
  'dev.to': 'DEV',
  'ko-fi.com': 'Ko-fi',
  'patreon.com': 'Patreon',
  'wikipedia.org': 'Wikipedia',
  'wikidata.org': 'Wikidata',
  'crunchbase.com': 'Crunchbase',
  'facebook.com': 'Facebook',
};

String linkPlatform(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  for (final entry in _knownHosts.entries) {
    if (host == entry.key || host.endsWith('.${entry.key}')) {
      return entry.value;
    }
  }
  return '';
}

String linkHost(String url) =>
    Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url;

class LinksCard extends StatelessWidget {
  const LinksCard({
    super.key,
    required this.user,
    required this.isOwner,
    required this.users,
    this.onChanged,
  });

  final UserProfile user;
  final bool isOwner;
  final UserService users;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final links = user.profile.links;
    final socials = [
      for (final link in links)
        if (linkPlatform(link.url).isNotEmpty) link,
    ];
    final sites = [
      for (final link in links)
        if (linkPlatform(link.url).isEmpty) link,
    ];
    return UserCard(
      title: context.t('user:links'),
      trailing: isOwner
          ? IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit01,
                size: 16,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: context.t('user:linksEdit'),
              onPressed: () => _openEdit(context),
            )
          : null,
      child: links.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.t('user:noLinks')}\n${context.t('user:noLinksDescription')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: () => _openEdit(context),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedLink01,
                      size: 14,
                    ),
                    label: Text(context.t('user:linksAdd')),
                  ),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (socials.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final link in socials)
                        Tooltip(
                          message: link.label,
                          child: ActionChip(
                            avatar: SvgPicture.asset(
                              resolveLink(link.url).asset,
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            ),
                            label: Text(
                              linkPlatform(link.url),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => launchUrl(
                              Uri.parse(link.url),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (sites.isNotEmpty) ...[
                  if (socials.isNotEmpty) const SizedBox(height: 4),
                  for (final link in sites)
                    InkWell(
                      onTap: () => launchUrl(
                        Uri.parse(link.url),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    link.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    linkHost(link.url),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowUpRight01,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  void _openEdit(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(
      _LinksEditSheet(
        links: user.profile.links,
        users: users,
        onChanged: onChanged,
      ).asAdaptiveSheetRoute<void>(),
    );
  }
}

class _LinksEditSheet extends StatefulWidget {
  const _LinksEditSheet({
    required this.links,
    required this.users,
    this.onChanged,
  });

  final List<ProfileLink> links;
  final UserService users;
  final VoidCallback? onChanged;

  @override
  State<_LinksEditSheet> createState() => _LinksEditSheetState();
}

class _LinksEditSheetState extends State<_LinksEditSheet> {
  late final List<ProfileLink> _links = List.of(widget.links);
  bool _busy = false;

  static const _limit = 12;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged?.call();
    } catch (_) {
      // reload via refresh
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editLink([ProfileLink? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _LinkDialog(link: existing, users: widget.users),
    );
    if (saved == true) {
      widget.onChanged?.call();
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _move(int index, int delta) async {
    final next = index + delta;
    if (next < 0 || next >= _links.length) return;
    setState(() {
      final item = _links.removeAt(index);
      _links.insert(next, item);
    });
    await _run(
      () => widget.users.reorderProfileLinks([
        for (final link in _links) link.id,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text(
                context.t('user:linksEdit'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_links.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                context.t('user:noLinks'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (var i = 0; i < _links.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _links[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          linkHost(_links[i].url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowUp01,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy || i == 0 ? null : () => _move(i, -1),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy || i == _links.length - 1
                        ? null
                        : () => _move(i, 1),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: context.t('user:linksEditLink'),
                    onPressed: _busy ? null : () => _editLink(_links[i]),
                  ),
                  IconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: _busy
                        ? null
                        : () => _run(() async {
                            await widget.users.deleteProfileLink(_links[i].id);
                            setState(() => _links.removeAt(i));
                          }),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _busy || _links.length >= _limit
                  ? null
                  : () => _editLink(),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 14,
              ),
              label: Text(
                _links.length >= _limit
                    ? context.t('user:linksLimitReached')
                    : context.t('user:linksAddLink'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({this.link, required this.users});

  final ProfileLink? link;
  final UserService users;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final _label = TextEditingController(text: widget.link?.label);
  late final _url = TextEditingController(text: widget.link?.url);
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _label.text.trim();
    final url = _url.text.trim();
    if (_saving || label.isEmpty || url.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.link == null) {
        await widget.users.createProfileLink(label: label, url: url);
      } else {
        await widget.users.updateProfileLink(
          widget.link!.id,
          label: label,
          url: url,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      context.t(
        widget.link == null ? 'user:linksAddLink' : 'user:linksEditLink',
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _label,
          decoration: InputDecoration(
            labelText: context.t('user:linkLabel'),
            hintText: context.t('user:linkLabelPlaceholder'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: context.t('user:linkUrl'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.t('common:cancel')),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(context.t('common:save')),
      ),
    ],
  );
}
