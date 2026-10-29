import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/game_detail.dart';

const _websiteIcons = {
  'Steam': 'steam',
  'Wikipedia': 'wikipedia',
  'Twitch': 'twitch',
  'Subreddit': 'reddit',
  'Discord': 'discord',
  'YouTube': 'youtube',
  'Twitter': 'x',
  'Facebook': 'facebook',
  'Instagram': 'instagram',
  'Bluesky': 'bluesky',
};

class WebsiteIcon extends StatelessWidget {
  const WebsiteIcon({super.key, required this.website, required this.onTap});

  final GameWebsite website;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asset = _websiteIcons[website.name];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: asset != null
            ? SvgPicture.asset(
                'assets/icons/social/$asset.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              )
            : HugeIcon(
                icon: HugeIcons.strokeRoundedLink01,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
