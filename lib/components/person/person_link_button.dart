import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/social_links.dart';

class PersonLinkButton extends StatelessWidget {
  const PersonLinkButton({super.key, required this.link});

  final PersonLink link;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: link.label,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => launchUrl(
            Uri.parse(link.href),
            mode: LaunchMode.externalApplication,
          ),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: link.asset.isEmpty
                  ? HugeIcon(
                      icon: link.key == 'homepage'
                          ? HugeIcons.strokeRoundedLinkSquare01
                          : HugeIcons.strokeRoundedLink01,
                      size: 20,
                      color: color,
                    )
                  : SvgPicture.asset(
                      link.asset,
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
