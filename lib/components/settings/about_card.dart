import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n_context.dart';
import '../../controllers/tour_controller.dart';
import '../../utils/haptics.dart';
import 'settings_card.dart';

const _sourceUrl = 'https://github.com/TrackGeek/mobile';

const _sources = [
  ('settings:about.games', 'IGDB'),
  ('settings:about.tvAndMovies', 'TMDB'),
  ('settings:about.animes', 'MAL + Tenrai'),
  ('settings:about.mangas', 'Anilist'),
  ('settings:about.books', 'Hardcover.app'),
];

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          icon: HugeIcons.strokeRoundedHelpCircle,
          title: context.t('app:tour.menu'),
          description: context.t('app:tour.menuDescription'),
          children: [
            OutlinedButton(
              onPressed: () {
                HapticsHelper.light();
                Navigator.of(context).popUntil((route) => route.isFirst);
                TourController.instance.start();
              },
              child: Text(context.t('app:tour.menu')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: HugeIcons.strokeRoundedDatabase,
          title: context.t('settings:about.metadataTitle'),
          description: context.t('settings:about.metadataDescription'),
          children: [
            for (final (labelKey, source) in _sources)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t(labelKey),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      source,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          icon: HugeIcons.strokeRoundedGithub,
          title: context.t('settings:about.sourceTitle'),
          description: context.t('settings:about.sourceDescription'),
          children: [
            OutlinedButton.icon(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedLinkSquare01,
                size: 16,
              ),
              label: Text(context.t('settings:about.sourceAction')),
              onPressed: () {
                HapticsHelper.light();
                launchUrl(
                  Uri.parse(_sourceUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
