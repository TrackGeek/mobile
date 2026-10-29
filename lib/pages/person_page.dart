import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/layout/content_frame.dart';
import '../components/person/person_aliases.dart';
import '../components/person/person_app_bar_title.dart';
import '../components/person/person_biography.dart';
import '../components/person/person_credits_section.dart';
import '../components/person/person_error.dart';
import '../components/person/person_hero.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/media_type.dart';
import '../models/person.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/media_detail_service.dart';
import '../services/person_service.dart';
import '../utils/dates.dart';
import '../utils/markdown_utils.dart';
import 'media_detail_page.dart';

const _pageSize = 24;
const _siteUrl = 'https://trackgeek.net';

sealed class PersonRequest {
  const PersonRequest();

  String get sharePath;
}

final class PersonSlugRequest extends PersonRequest {
  const PersonSlugRequest(this.slug);

  final String slug;

  @override
  String get sharePath => 'cast/$slug';
}

final class MangaCastRequest extends PersonRequest {
  const MangaCastRequest(this.anilistId);

  final String anilistId;

  @override
  String get sharePath => 'manga/cast/$anilistId';
}

class PersonPage extends StatefulWidget {
  const PersonPage({
    super.key,
    required this.request,
    required this.people,
    required this.details,
    required this.favorites,
    required this.session,
    required this.api,
    this.onOpenUser,
    this.onOpenGenre,
    this.onOpenSettings,
  });

  final PersonRequest request;
  final PersonService people;
  final MediaDetailService details;
  final FavoriteService favorites;
  final SessionController session;
  final ApiClient api;
  final void Function(String username)? onOpenUser;
  final void Function(MediaType type, String genre)? onOpenGenre;
  final VoidCallback? onOpenSettings;

  @override
  State<PersonPage> createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  final _scroll = ScrollController();
  Future<Person>? _future;
  bool? _favorited;
  bool _favoriteBusy = false;
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _scroll.addListener(_maybeShowMore);
  }

  Future<Person> _load() async {
    final language = L10nScope.of(context).language;
    final results = await Future.wait([
      switch (widget.request) {
        PersonSlugRequest(:final slug) => widget.people.person(
          slug,
          language: language,
        ),
        MangaCastRequest(:final anilistId) => widget.people.mangaCast(
          anilistId,
          language: language,
        ),
      },
      ensureDateLocale(language),
    ]);
    final person = results[0] as Person;
    if (widget.session.loggedIn) {
      _loadFavoriteStatus(person);
    }
    return person;
  }

  Future<void> _loadFavoriteStatus(Person person) async {
    try {
      final status = await widget.favorites.status(
        FavoriteTarget.person,
        person.id,
      );
      if (mounted) setState(() => _favorited = status);
    } catch (_) {
      if (mounted) setState(() => _favorited = false);
    }
  }

  void _maybeShowMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
      setState(() => _visible += _pageSize);
    }
  }

  Future<void> _toggleFavorite(Person person) async {
    final isFavorited = _favorited ?? false;
    setState(() => _favoriteBusy = true);
    try {
      await widget.favorites.toggle(
        FavoriteTarget.person,
        person.id,
        isFavorited,
      );
      if (mounted) setState(() => _favorited = !isFavorited);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('api:INTERNAL_SERVER_ERROR'))),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _share(Person person) async {
    final url = '$_siteUrl/${widget.request.sharePath}';
    final shareText =
        person.source == PersonSource.anilist && person.biography != null
        ? stripMarkdown(person.biography!)
        : person.biography;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          title: person.name,
          text: shareText == null || shareText.isEmpty
              ? url
              : '$shareText\n$url',
        ),
      );
      if (result.status == ShareResultStatus.dismissed) return;
      if (result.status == ShareResultStatus.success) return;
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('common:linkCopied'))));
    }
  }

  MediaDetailEnv get _env => (
    api: widget.api,
    session: widget.session,
    details: widget.details,
    people: widget.people,
    favorites: widget.favorites,
    progress: null,
    onOpenUser: widget.onOpenUser,
    onOpenGenre: widget.onOpenGenre,
    onOpenSettings: widget.onOpenSettings,
  );

  void _openCredit(PersonCredit credit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: credit.mediaType,
          id: '${credit.id}',
          details: widget.details,
          env: _env,
        ),
      ),
    );
  }

  void _openMarkdownLink(String? href) {
    final internal = internalAnilistPath(href);
    if (internal != null) {
      final id = internal.split('/').last;
      if (internal.startsWith('/manga/cast/')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PersonPage(
              request: MangaCastRequest(id),
              people: widget.people,
              details: widget.details,
              favorites: widget.favorites,
              session: widget.session,
              api: widget.api,
              onOpenUser: widget.onOpenUser,
              onOpenGenre: widget.onOpenGenre,
              onOpenSettings: widget.onOpenSettings,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => mediaDetailPage(
              type: MediaType.manga,
              id: id,
              details: widget.details,
              env: _env,
            ),
          ),
        );
      }
      return;
    }
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: PersonAppBarTitle(future: _future)),
      body: FutureBuilder<Person>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return PersonError(
              error: snapshot.error,
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final person = snapshot.data;
          if (person == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ContentFrame(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PersonHero(
                          person: person,
                          canFavorite: widget.session.loggedIn,
                          favorited: _favorited ?? false,
                          favoriteBusy: _favoriteBusy || _favorited == null,
                          onToggleFavorite: () => _toggleFavorite(person),
                          onShare: () => _share(person),
                        ),
                        if (person.biography != null &&
                            person.biography!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          PersonBiography(
                            biography: person.biography!,
                            name: person.name,
                            markdown: person.source == PersonSource.anilist,
                            onOpenLink: _openMarkdownLink,
                          ),
                        ],
                        if (person.alsoKnownAs.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          PersonAliases(aliases: person.alsoKnownAs),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: PersonCreditsSection(
                    person: person,
                    visible: _visible,
                    heading: widget.request is MangaCastRequest
                        ? context.t('library:catalog')
                        : null,
                    user: widget.session.user,
                    onOpenCredit: _openCredit,
                    onResetPaging: () => setState(() => _visible = _pageSize),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
