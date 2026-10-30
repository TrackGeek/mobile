import 'package:flutter/material.dart';

import '../components/details/media_summary_header.dart';
import '../components/details/media_summary_fields.dart';
import '../components/layout/content_frame.dart';
import '../styles/tg_layout.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/media_detail.dart';
import '../models/media_type.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/media_detail_service.dart';
import '../services/person_service.dart';
import '../services/progress_service.dart';
import 'anime_detail_page.dart';
import 'book_detail_page.dart';
import 'game_detail_page.dart';
import 'manga_detail_page.dart';
import 'movie_detail_page.dart';
import 'tv_detail_page.dart';
import '../components/media/smooth_image.dart';

typedef MediaDetailEnv = ({
  ApiClient api,
  SessionController session,
  MediaDetailService details,
  PersonService people,
  FavoriteService favorites,
  ProgressService? progress,
  void Function(String username)? onOpenUser,
  void Function(MediaType type, String genre)? onOpenGenre,
  VoidCallback? onOpenSettings,
});

Widget mediaDetailPage({
  required MediaType type,
  required String id,
  required MediaDetailService details,
  MediaDetailEnv? env,
}) {
  if (type == MediaType.anime && env != null) {
    return AnimeDetailPage(slug: id, env: env);
  }
  if (type == MediaType.book && env != null) {
    return BookDetailPage(hardcoverId: id, env: env);
  }
  if (type == MediaType.game && env != null) {
    return GameDetailPage(igdbId: id, env: env);
  }
  if (type == MediaType.manga && env != null) {
    return MangaDetailPage(anilistId: id, env: env);
  }
  if (type == MediaType.movie && env != null) {
    return MovieDetailPage(tmdbId: id, env: env);
  }
  if (type == MediaType.tv && env != null) {
    return TvDetailPage(tmdbId: id, env: env);
  }
  return MediaDetailPage(details: details, type: type, id: id);
}

class MediaDetailPage extends StatelessWidget {
  const MediaDetailPage({
    super.key,
    required this.details,
    required this.type,
    required this.id,
  });

  final MediaDetailService details;
  final MediaType type;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('common:viewDetails'))),
      body: FutureBuilder<MediaDetail>(
        future: details.detail(type, id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(context.t('common:internalError')));
          }
          final media = snapshot.data;
          if (media == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ContentFrame(
            maxWidth: TgLayout.readingWidth,
            child: ListView(
              children: [
                if (media.backdropUrl != null)
                  AspectRatio(
                    aspectRatio: 16 / 5,
                    child: SmoothImage(url: media.backdropUrl!),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaSummaryHeader(media: media),
                      if (media.chips.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final chip in media.chips)
                              Chip(label: Text(chip)),
                          ],
                        ),
                      ],
                      if (media.fields.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        MediaSummaryFields(media: media),
                      ],
                      if (media.description != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          media.type == MediaType.movie ||
                                  media.type == MediaType.tv
                              ? context.t('common:overview')
                              : context.t('common:synopsis'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(media.description!),
                      ],
                    ],
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
