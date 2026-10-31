import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/user_profile.dart';
import '../../utils/profile_cosmetics.dart';
import 'user_widgets.dart';
import '../media/smooth_image.dart';
import '../../styles/tg_theme.dart';
import '../../utils/numbers.dart';
import '../../utils/strings.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    required this.isOwner,
    this.isAuthenticated = false,
    this.isFollowing = false,
    this.followsYou = false,
    this.followBusy = false,
    this.onFollow,
    this.onEdit,
    this.onOpenFollowers,
    this.onOpenFollowing,
  });

  final UserProfile user;
  final bool isOwner;
  final bool isAuthenticated;
  final bool isFollowing;
  final bool followsYou;
  final bool followBusy;
  final VoidCallback? onFollow;
  final VoidCallback? onEdit;
  final VoidCallback? onOpenFollowers;
  final VoidCallback? onOpenFollowing;

  static const _bannerHeight = 120.0;
  static const _avatarSize = 84.0;

  String? _titleLabel(BuildContext context) {
    final title = user.profile.title;
    if (!title.isUsable || title == 'none') return null;
    final key = 'cosmetics:titles.$title';
    final label = context.t(key);
    return label == key ? title : label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = L10nScope.of(context).language;
    final color = user.profile.color;
    final createdAt = user.createdAt;
    final bannerUrl = user.profile.bannerUrl;
    final effectKey = user.profile.bannerEffect ?? 'none';
    final titleLabel = _titleLabel(context);
    final tier = user.tier;
    final hasTier = tier != null && tier.isNotEmpty;
    final action = isOwner
        ? FilledButton.tonalIcon(
            onPressed: onEdit,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit01,
              size: 18,
            ),
            label: Text(context.t('user:editProfile')),
          )
        : isAuthenticated
        ? (isFollowing
              ? FilledButton.tonalIcon(
                  onPressed: followBusy ? null : onFollow,
                  icon: _followIcon(HugeIcons.strokeRoundedUserRemove01),
                  label: Text(context.t('user:unfollow')),
                )
              : FilledButton.icon(
                  onPressed: followBusy ? null : onFollow,
                  icon: _followIcon(HugeIcons.strokeRoundedUserAdd01),
                  label: Text(context.t('user:follow')),
                ))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _bannerHeight + _avatarSize / 2,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _bannerHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerUrl.isUsable)
                      SmoothImage(
                        url: bannerUrl!,
                        error: Container(
                          decoration: profileColorDecoration(color, radius: 0),
                        ),
                      )
                    else
                      Container(
                        decoration: profileColorDecoration(color, radius: 0),
                      ),
                    Container(decoration: BannerEffects.decoration(effectKey)),
                    if (BannerEffects.painter(effectKey) != null)
                      CustomPaint(painter: BannerEffects.painter(effectKey)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.55, 1],
                          colors: [
                            Colors.transparent,
                            scheme.surface.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surface,
                  ),
                  child: UserAvatar(
                    name: user.name,
                    avatarUrl: user.profile.avatarUrl,
                    frame: user.profile.avatarFrame,
                    size: _avatarSize - 8,
                  ),
                ),
              ),
              if (action != null)
                Positioned(right: 16, bottom: 4, child: action),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '@${user.username}'),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.t('user:copyProfileUsernameSuccess'),
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        '@${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (followsYou) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.t('user:followsYou'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: profileColorDecoration(color, radius: 20),
                    child: Text(
                      context.t('xp:levelShort', {'level': user.xp.level}),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                      ),
                    ),
                  ),
                  if (titleLabel != null)
                    _Badge(
                      icon: HugeIcons.strokeRoundedAward01,
                      text: titleLabel,
                      color: scheme.primary,
                    ),
                  if (hasTier)
                    _Badge(
                      icon: HugeIcons.strokeRoundedCrown,
                      text: context.t('common:tiers.$tier'),
                      color: scheme.primary,
                    ),
                ],
              ),
              if (createdAt != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${context.t('common:joinedAt')} ${DateFormat.yMd(locale).format(createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _Stat(
                icon: HugeIcons.strokeRoundedAward01,
                label: context.t('user:medals'),
                count: user.userMedals.length,
              ),
              const SizedBox(width: 10),
              _Stat(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: context.t('user:follower', {'count': user.followers}),
                count: user.followers,
                onTap: onOpenFollowers,
              ),
              const SizedBox(width: 10),
              _Stat(
                icon: HugeIcons.strokeRoundedUserCheck01,
                label: context.t('common:following'),
                count: user.following,
                onTap: onOpenFollowing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _followIcon(List<List<dynamic>> icon) => followBusy
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : HugeIcon(icon: icon, size: 18);
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, required this.color});

  final List<List<dynamic>> icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.count,
    this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(TgRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.16),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 24,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count.humanizedCount(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
