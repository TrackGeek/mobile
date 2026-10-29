import '../models/anime_detail.dart';
import 'social_links.dart';

List<PersonLink> animeExternalLinks(AnimeDetail anime) {
  final links = <PersonLink>[];
  var hasMal = false;
  for (final entry in anime.external) {
    final name = entry.name.toLowerCase();
    final url = entry.url;
    if (url.isEmpty) continue;
    if (name.contains('official')) {
      links.add(
        PersonLink(
          key: 'official-${links.length}',
          href: url,
          asset: '',
          label: entry.name,
        ),
      );
      continue;
    }
    if (name.contains('instagram')) {
      links.add(
        PersonLink(
          key: 'instagram-${links.length}',
          href: url,
          asset: 'assets/icons/social/instagram.svg',
          label: 'Instagram',
        ),
      );
      continue;
    }
    if (name.contains('facebook')) {
      links.add(
        PersonLink(
          key: 'facebook-${links.length}',
          href: url,
          asset: 'assets/icons/social/facebook.svg',
          label: 'Facebook',
        ),
      );
      continue;
    }
    if (name.contains('youtube')) {
      links.add(
        PersonLink(
          key: 'youtube-${links.length}',
          href: url,
          asset: 'assets/icons/social/youtube.svg',
          label: 'YouTube',
        ),
      );
      continue;
    }
    if (name.contains('baidu')) {
      links.add(
        PersonLink(
          key: 'baidu-${links.length}',
          href: url,
          asset: '',
          label: 'Baidu',
        ),
      );
      continue;
    }
    if (name.contains('douban')) {
      links.add(
        PersonLink(
          key: 'douban-${links.length}',
          href: url,
          asset: '',
          label: 'Douban',
        ),
      );
      continue;
    }
    if (name.startsWith('@') || name.contains('twitter')) {
      links.add(
        PersonLink(
          key: 'x-${links.length}',
          href: url,
          asset: 'assets/icons/social/x.svg',
          label: 'X',
        ),
      );
      continue;
    }
    if (name.contains('ann')) {
      links.add(
        PersonLink(
          key: 'ann-${links.length}',
          href: url,
          asset: '',
          label: 'ANN',
        ),
      );
      continue;
    }
    if (name.contains('wikipedia')) {
      links.add(
        PersonLink(
          key: 'wikipedia-${links.length}',
          href: url,
          asset: 'assets/icons/social/wikipedia.svg',
          label: 'Wikipedia',
        ),
      );
      continue;
    }
    if (url.contains('myanimelist.net')) hasMal = true;
    final resolved = resolveLink(url);
    links.add(
      PersonLink(
        key: 'link-${links.length}',
        href: url,
        asset: resolved.asset,
        label: entry.name.isEmpty
            ? (resolved.platform ?? resolved.host)
            : entry.name,
      ),
    );
  }
  if (!hasMal) {
    links.add(
      PersonLink(
        key: 'mal',
        href: 'https://myanimelist.net/anime/${anime.malId}',
        asset: 'assets/icons/social/myanimelist.svg',
        label: 'MyAnimeList',
      ),
    );
  }
  return links;
}
