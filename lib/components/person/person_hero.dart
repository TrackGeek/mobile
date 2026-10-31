import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/person.dart';
import '../../utils/dates.dart';
import '../../utils/social_links.dart';
import 'person_action_button.dart';
import 'person_image.dart';
import 'person_link_button.dart';
import 'person_meta_item.dart';
import '../media/smooth_image.dart';

class PersonHero extends StatelessWidget {
  const PersonHero({
    super.key,
    required this.person,
    required this.canFavorite,
    required this.favorited,
    required this.favoriteBusy,
    required this.onToggleFavorite,
    required this.onShare,
  });

  final Person person;
  final bool canFavorite;
  final bool favorited;
  final bool favoriteBusy;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backdropUrl = person.credits
        .where((credit) => credit.backdropUrl != null)
        .map((credit) => credit.backdropUrl!)
        .firstOrNull;
    final links = personExternalLinks(person);
    final age = ageFrom(person.birthday, person.deathday);
    final language = L10nScope.of(context).language;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: backdropUrl != null
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          1.3937,
                          -0.3576,
                          -0.0361,
                          0,
                          0,
                          -0.1063,
                          1.7880,
                          -0.0361,
                          0,
                          0,
                          -0.1063,
                          -0.3576,
                          1.4639,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: Transform.scale(
                          scale: 1.1,
                          child: SmoothImage(url: backdropUrl),
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                            theme.colorScheme.surface,
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.5),
                      theme.colorScheme.surface.withValues(alpha: 0.85),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    PersonImage(person: person),
                    const SizedBox(height: 24),
                    if (person.knownForDepartment != null &&
                        person.knownForDepartment!.isNotEmpty)
                      Text(
                        person.knownForDepartment!.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.4,
                        ),
                      ),
                    Text(
                      person.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        if (formatLongDate(person.birthday, language)
                            case final birthday?)
                          PersonMetaItem(
                            icon: HugeIcons.strokeRoundedBirthdayCake,
                            text:
                                birthday +
                                (age != null
                                    ? ', ${context.t('library:yearsOld', {'count': age})}'
                                    : ''),
                          ),
                        if (formatLongDate(person.deathday, language)
                            case final deathday?)
                          PersonMetaItem(
                            icon: HugeIcons.strokeRoundedFlower,
                            text: deathday,
                          ),
                        if (person.placeOfBirth != null &&
                            person.placeOfBirth!.isNotEmpty)
                          PersonMetaItem(
                            icon: HugeIcons.strokeRoundedLocation01,
                            text: person.placeOfBirth!,
                          ),
                        PersonMetaItem(
                          icon: HugeIcons.strokeRoundedLayers01,
                          text: context.t('library:creditCount', {
                            'count': person.stats.total,
                          }),
                        ),
                      ],
                    ),
                    if (links.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final link in links)
                            PersonLinkButton(link: link),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  if (canFavorite)
                    PersonActionButton(
                      icon: HugeIcons.strokeRoundedFavourite,
                      color: favorited ? Colors.red : null,
                      tooltip: context.t('common:favorite'),
                      disabled: favoriteBusy,
                      onPressed: onToggleFavorite,
                    ),
                  const SizedBox(width: 8),
                  PersonActionButton(
                    icon: HugeIcons.strokeRoundedShare08,
                    tooltip: context.t('feed:share'),
                    onPressed: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
