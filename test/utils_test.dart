import 'package:flutter_test/flutter_test.dart';
import 'package:trackgeek/models/person.dart';
import 'package:trackgeek/services/auth_service.dart';
import 'package:trackgeek/utils/content_types.dart';
import 'package:trackgeek/utils/dates.dart';
import 'package:trackgeek/utils/episode_backfill.dart';
import 'package:trackgeek/utils/markdown_utils.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/utils/social_links.dart';
import 'package:trackgeek/utils/watch_links.dart';
import 'package:trackgeek/utils/watch_time.dart';

void main() {
  group('formatLongDate', () {
    test('formats ISO dates in the given locale', () async {
      await ensureDateLocale('en-US');
      expect(
        formatLongDate('1964-09-02T00:00:00.000Z', 'en-US'),
        'September 2, 1964',
      );
    });

    test('returns null for missing or invalid input', () {
      expect(formatLongDate(null, 'en-US'), isNull);
      expect(formatLongDate('', 'en-US'), isNull);
      expect(formatLongDate('nope', 'en-US'), isNull);
    });
  });

  group('ageFrom', () {
    test('computes age at death or today', () {
      expect(ageFrom('2000-01-01', '2020-06-01'), 20);
      expect(ageFrom('2000-12-01', '2020-06-01'), 19);
      expect(ageFrom(null, null), isNull);
    });
  });

  group('stripMarkdown', () {
    test('removes links, images and markers', () {
      expect(
        stripMarkdown('**Bold** [text](https://x.test) ![img](https://i.test)'),
        'Bold text',
      );
    });
  });

  group('internalAnilistPath', () {
    test('maps staff and manga urls to internal paths', () {
      expect(
        internalAnilistPath('https://anilist.co/staff/105167/name'),
        '/manga/cast/105167',
      );
      expect(
        internalAnilistPath('https://anilist.co/manga/30002/x'),
        '/manga/30002',
      );
    });

    test('rejects other hosts and non-numeric ids', () {
      expect(internalAnilistPath('https://google.com/staff/1'), isNull);
      expect(internalAnilistPath('https://anilist.co/staff/x'), isNull);
      expect(internalAnilistPath(null), isNull);
    });
  });

  group('personExternalLinks', () {
    Person person({Map<String, dynamic>? external, String? homepage}) => Person(
      id: 'p1',
      slug: 'x',
      name: 'X',
      alsoKnownAs: const [],
      images: const [],
      external: external,
      homepage: homepage,
      source: PersonSource.tmdb,
      credits: const [],
      stats: const PersonStats(
        total: 0,
        movies: 0,
        tvShows: 0,
        anime: 0,
        tracked: 0,
      ),
    );

    test('builds spec links in order and resolves leftover urls', () {
      final links = personExternalLinks(
        person(
          external: {
            'imdb_id': 'nm0000206',
            'youtube_id': 'UCabc',
            'blog': 'https://x.com/me',
          },
          homepage: 'https://me.test',
        ),
      );
      expect(links.map((l) => l.key), ['imdb', 'youtube', 'blog', 'homepage']);
      expect(links[0].href, 'https://www.imdb.com/name/nm0000206');
      expect(links[1].href, 'https://www.youtube.com/channel/UCabc');
      expect(links[2].label, 'X');
      expect(links[3].asset, isEmpty);
    });

    test('returns empty list without external data', () {
      expect(personExternalLinks(person()), isEmpty);
    });
  });

  group('unwatchedPreviousSeasonEpisodes', () {
    test('skips specials and collects gaps across earlier seasons', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 0, totalEpisodes: 2, watchedEpisodes: const []),
        (seasonNumber: 1, totalEpisodes: 3, watchedEpisodes: const [1]),
        (seasonNumber: 2, totalEpisodes: 4, watchedEpisodes: const [2]),
      ];
      expect(unwatchedPreviousSeasonEpisodes(seasons, 2, 3), [
        (season: 1, episode: 2),
        (season: 1, episode: 3),
        (season: 2, episode: 1),
      ]);
    });

    test('returns empty when nothing earlier is missing', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 1, totalEpisodes: 2, watchedEpisodes: const [1, 2]),
      ];
      expect(unwatchedPreviousSeasonEpisodes(seasons, 1, 1), isEmpty);
    });
  });

  group('nextEpisodeFromSeasons', () {
    test('finds first unwatched episode across seasons', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 2, totalEpisodes: 2, watchedEpisodes: const []),
        (seasonNumber: 1, totalEpisodes: 2, watchedEpisodes: const [1, 2]),
      ];
      expect(nextEpisodeFromSeasons(seasons), (season: 2, episode: 1));
    });

    test('falls back to last episode of last season when all watched', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 1, totalEpisodes: 2, watchedEpisodes: const [1, 2]),
        (seasonNumber: 0, totalEpisodes: 5, watchedEpisodes: const []),
      ];
      expect(nextEpisodeFromSeasons(seasons), (season: 1, episode: 2));
    });
  });

  group('remainingSeasonWatchHours', () {
    test('sums remaining episodes across seasons', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 1, totalEpisodes: 10, watchedEpisodes: const [1, 2]),
        (seasonNumber: 2, totalEpisodes: 10, watchedEpisodes: const []),
      ];
      final hours = remainingSeasonWatchHours(seasons, 50);
      expect(hours, 15.0);
    });

    test('returns null for invalid runtime or season data', () {
      final seasons = <SeasonWatchData>[
        (seasonNumber: 1, totalEpisodes: 10, watchedEpisodes: const []),
      ];
      expect(remainingSeasonWatchHours(seasons, null), isNull);
      expect(remainingSeasonWatchHours(const [], 50), isNull);
      expect(
        remainingSeasonWatchHours(const [
          (seasonNumber: 1, totalEpisodes: 0, watchedEpisodes: []),
        ], 50),
        isNull,
      );
    });
  });

  group('episodeRuntimeMinutesFromValues', () {
    test('averages positive runtimes', () {
      expect(episodeRuntimeMinutesFromValues([40, 50]), 45);
      expect(episodeRuntimeMinutesFromValues([0, -5]), isNull);
    });
  });

  group('visibleMediaTypes', () {
    test('returns all types when unset', () {
      expect(visibleMediaTypes(null), MediaType.values.toSet());
      expect(
        visibleMediaTypes(const SessionUser(id: '1', name: 'n', email: 'e')),
        MediaType.values.toSet(),
      );
    });

    test('maps stored api names to slugs', () {
      final visible = visibleMediaTypes(
        const SessionUser(
          id: '1',
          name: 'n',
          email: 'e',
          contentTypes: ['Movie', 'Anime'],
        ),
      );
      expect(visible, {MediaType.movie, MediaType.anime});
    });
  });
}
