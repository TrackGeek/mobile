import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/user_profile.dart';
import '../../utils/profile_cosmetics.dart';
import 'user_widgets.dart';
import '../media/smooth_image.dart';
import '../../utils/numbers.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = L10nScope.of(context).language;
    final color = user.profile.color;
    final createdAt = user.createdAt;
    final bannerUrl = user.profile.bannerUrl;
    final effectKey = user.profile.bannerEffect ?? 'none';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (bannerUrl != null && bannerUrl.isNotEmpty)
                      SmoothImage(
                        url: bannerUrl,
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            theme.colorScheme.surface,
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 4,
                    ),
                  ),
                  child: UserAvatar(
                    name: user.name,
                    avatarUrl: user.profile.avatarUrl,
                    frame: user.profile.avatarFrame,
                    size: 72,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: profileColorDecoration(color, radius: 6),
                      child: Text(
                        context.t('xp:levelShort', {'level': user.xp.level}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (user.profile.title != null && user.profile.title!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      user.profile.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: InkWell(
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (followsYou) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.t('user:followsYou'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (createdAt != null || (user.tier != null && user.tier!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (createdAt != null)
                  _MetaItem(
                    icon: HugeIcons.strokeRoundedCalendar01,
                    text:
                        '${context.t('common:joinedAt')} ${DateFormat.yMd(locale).format(createdAt)}',
                  ),
                if (user.tier != null && user.tier!.isNotEmpty)
                  _MetaItem(
                    icon: HugeIcons.strokeRoundedCrown,
                    text: user.tierStartedAt == null
                        ? context.t('common:tiers.${user.tier}')
                        : '${context.t('common:tierStartedAt')} ${DateFormat.yMd(locale).format(DateTime.tryParse(user.tierStartedAt!) ?? createdAt ?? DateTime.now())}, ${context.t('common:tiers.${user.tier}')}',
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              _StatPill(
                icon: HugeIcons.strokeRoundedAward01,
                label: context.t('user:medals'),
                count: user.userMedals.length,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: context.t('user:follower', {'count': user.followers}),
                count: user.followers,
                onTap: onOpenFollowers,
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: context.t('common:following'),
                count: user.following,
                onTap: onOpenFollowing,
              ),
            ],
          ),
        ),

        if (isOwner || isAuthenticated)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: isOwner
                  ? FilledButton.tonalIcon(
                      onPressed: onEdit,
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit01,
                        size: 16,
                      ),
                      label: Text(context.t('user:editProfile')),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: followBusy ? null : onFollow,
                      icon: followBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : HugeIcon(
                              icon: isFollowing
                                  ? HugeIcons.strokeRoundedUserRemove01
                                  : HugeIcons.strokeRoundedUserAdd01,
                              size: 16,
                            ),
                      label: Text(
                        context.t(
                          isFollowing ? 'user:unfollow' : 'user:follow',
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final List<List<dynamic>> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                count.humanizedCount(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: icon,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
