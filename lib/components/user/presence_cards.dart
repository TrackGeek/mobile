import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../models/discord_presence.dart';
import '../../services/user_service.dart';
import 'user_widgets.dart';

String formatElapsed(Duration d) {
  final seconds = d.inSeconds.clamp(0, 1 << 31);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  final padded = '$secs'.padLeft(2, '0');
  if (hours == 0) return '$minutes:$padded';
  return '$hours:${'$minutes'.padLeft(2, '0')}:$padded';
}

const _statusColors = {
  'online': Color(0xFF22C55E),
  'idle': Color(0xFFEAB308),
  'dnd': Color(0xFFEF4444),
  'offline': Color(0xFF6B7280),
};

const _statusLabels = {
  'online': 'user:discordStatusOnline',
  'idle': 'user:discordStatusIdle',
  'dnd': 'user:discordStatusDnd',
  'offline': 'user:discordStatusOffline',
};

class PresenceCards extends StatefulWidget {
  const PresenceCards({super.key, required this.userId, required this.users});

  final String userId;
  final UserService users;

  @override
  State<PresenceCards> createState() => _PresenceCardsState();
}

class _PresenceCardsState extends State<PresenceCards> {
  DiscordPresence? _presence;
  bool _loaded = false;
  Timer? _poll;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _load(silent: true),
    );
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final presence = await widget.users.discordPresence(
        widget.userId,
        language: L10nScope.of(context).language,
      );
      if (mounted) {
        setState(() {
          _presence = presence;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presence = _presence;
    final showSpotify = !_loaded || presence?.spotify != null;
    final showDiscord =
        !_loaded ||
        presence?.status != null ||
        (presence?.activities.isNotEmpty ?? false);
    if (!showSpotify && !showDiscord) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          if (showSpotify) _SpotifyCard(presence: presence, loaded: _loaded),
          if (showSpotify && showDiscord) const SizedBox(height: 16),
          if (showDiscord) _DiscordCard(presence: presence, loaded: _loaded),
        ],
      ),
    );
  }
}

class _SpotifyCard extends StatelessWidget {
  const _SpotifyCard({required this.presence, required this.loaded});

  final DiscordPresence? presence;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spotify = presence?.spotify;
    return UserCard(
      title: context.t('user:spotify'),
      icon: HugeIcons.strokeRoundedSpotify,
      child: !loaded
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : spotify == null
          ? Text(
              '${context.t('user:noSpotify')}\n${context.t('user:noSpotifyDescription')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: spotify.albumArtUrl != null
                          ? Image.network(
                              spotify.albumArtUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _albumFallback(theme),
                            )
                          : _albumFallback(theme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: spotify.url == null
                                ? null
                                : () => launchUrl(
                                    Uri.parse(spotify.url!),
                                    mode: LaunchMode.externalApplication,
                                  ),
                            child: Text(
                              spotify.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (spotify.artists != null)
                            Text(
                              spotify.artists!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (spotify.album != null)
                            Text(
                              spotify.album!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (spotify.startedAt != null && spotify.endsAt != null)
                  _SpotifyProgress(spotify: spotify),
              ],
            ),
    );
  }

  Widget _albumFallback(ThemeData theme) => Container(
    width: 56,
    height: 56,
    color: theme.colorScheme.surfaceContainerHighest,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedMusicNote01,
      size: 22,
      color: Colors.white38,
    ),
  );
}

class _SpotifyProgress extends StatelessWidget {
  const _SpotifyProgress({required this.spotify});

  final DiscordSpotify spotify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final started = spotify.startedAt!;
    final ends = spotify.endsAt!;
    final now = DateTime.now();
    final elapsed = now.difference(started);
    final total = ends.difference(started);
    final ratio = total.inMilliseconds <= 0
        ? 0.0
        : (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final remaining = ends.difference(now);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: ratio, minHeight: 5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatElapsed(elapsed),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                '-${formatElapsed(remaining)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscordCard extends StatelessWidget {
  const _DiscordCard({required this.presence, required this.loaded});

  final DiscordPresence? presence;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activities = presence?.activities ?? const [];
    final status = presence?.status;
    return UserCard(
      title: context.t('user:discordActivity'),
      icon: HugeIcons.strokeRoundedDiscord,
      child: !loaded
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _statusColors[status] ??
                                _statusColors['offline'],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.t(_statusLabels[status] ?? ''),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (presence?.customStatus != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              presence!.customStatus!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (activities.isEmpty && status == null)
                  Text(
                    '${context.t('user:noDiscordActivity')}\n${context.t('user:noDiscordActivityDescription')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (final activity in activities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: activity.largeImageUrl != null
                              ? Image.network(
                                  activity.largeImageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _activityFallback(theme),
                                )
                              : _activityFallback(theme),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (activity.details != null)
                                Text(
                                  activity.details!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (activity.state != null)
                                Text(
                                  activity.state!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (activity.startedAt != null)
                                Text(
                                  context.t('user:discordActivityElapsed', {
                                    'value': formatElapsed(
                                      DateTime.now().difference(
                                        activity.startedAt!,
                                      ),
                                    ),
                                  }),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _activityFallback(ThemeData theme) => Container(
    width: 48,
    height: 48,
    color: theme.colorScheme.surfaceContainerHighest,
    child: const HugeIcon(
      icon: HugeIcons.strokeRoundedGameController01,
      size: 20,
      color: Colors.white38,
    ),
  );
}
