import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../components/details/detail_widgets.dart';
import '../components/franchise/franchise_banner_placeholder.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/media_type.dart';
import '../models/movie_detail.dart';
import '../services/movie_service.dart';
import 'media_detail_page.dart';

const _siteUrl = 'https://trackgeek.net';

class MovieFranchisePage extends StatefulWidget {
  const MovieFranchisePage({super.key, required this.slug, required this.env});

  final String slug;
  final MediaDetailEnv env;

  @override
  State<MovieFranchisePage> createState() => _MovieFranchisePageState();
}

class _MovieFranchisePageState extends State<MovieFranchisePage> {
  late final MovieService _movies;
  MovieFranchise? _franchise;
  var _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _movies = MovieService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final franchise = await _movies.franchise(
        widget.slug,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _franchise = franchise;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final franchise = _franchise;
    final imageUrl = franchise?.backdropUrl ?? franchise?.posterUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          franchise?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (franchise != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(text: '$_siteUrl/movie/franchises/${widget.slug}'),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || franchise == null
          ? DetailErrorState(onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ContentFrame(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: imageUrl == null || imageUrl.isEmpty
                            ? FranchiseBannerPlaceholder(theme: theme)
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        FranchiseBannerPlaceholder(
                                          theme: theme,
                                        ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        stops: const [0.1, 0.5],
                                        colors: [
                                          Colors.black.withValues(alpha: 0.55),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Text(
                                context.t('common:franchise'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            franchise.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (franchise.overview?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              franchise.overview!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            context.t('common:titleCount', {
                              'count': franchise.parts.length,
                            }),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (franchise.parts.isEmpty)
                            EmptyBlock(
                              icon: HugeIcons.strokeRoundedPackage,
                              title: context.t('common:noResults'),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: AdaptiveGridDelegate(
                                context: context,
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: franchise.parts.length,
                              itemBuilder: (context, index) =>
                                  _partCard(franchise.parts[index]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openPart(MovieFranchisePart part) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: MediaType.movie,
          id: '${part.tmdbId}',
          details: widget.env.details,
          env: widget.env,
        ),
      ),
    );
  }

  Widget _partCard(MovieFranchisePart part) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _openPart(part),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: part.isAdult
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: CoverArt(url: part.posterUrl),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '18+',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onError,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : CoverArt(url: part.posterUrl),
          ),
          const SizedBox(height: 6),
          Text(
            part.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (part.releaseDate != null && part.releaseDate!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    part.releaseDate!.split('-').first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
