import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/social_links.dart';

class ExternalLinksRow extends StatelessWidget {
  const ExternalLinksRow({super.key, required this.links});

  final List<PersonLink> links;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final link in links)
          IconButton(
            onPressed: () => _open(link.href),
            tooltip: link.label,
            icon: link.asset.isEmpty
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedLink01,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : SvgPicture.asset(
                    link.asset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
      ],
    );
  }
}
