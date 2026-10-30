import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../components/details/detail_widgets.dart';
import '../components/franchise/game_franchise_banner.dart';
import '../components/franchise/game_franchise_card.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/game_detail.dart';
import '../models/media_type.dart';
import '../services/game_service.dart';
import 'media_detail_page.dart';
import '../components/layout/tg_refresh_indicator.dart';

const _siteUrl = 'https://trackgeek.net';

class GameFranchisePage extends StatefulWidget {
  const GameFranchisePage({super.key, required this.slug, required this.env});

  final String slug;
  final MediaDetailEnv env;

  @override
  State<GameFranchisePage> createState() => _GameFranchisePageState();
}

class _GameFranchisePageState extends State<GameFranchisePage> {
  late final GameService _games;
  GameFranchise? _franchise;
  var _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _games = GameService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.of(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final franchise = await _games.franchise(widget.slug, language: language);
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

  void _openGame(FranchiseGame game) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: MediaType.game,
          id: '${game.igdbId}',
          details: widget.env.details,
          env: widget.env,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchise = _franchise;
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
                ShareParams(
                  text: '$_siteUrl/game/franchises/${franchise.slug}',
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || franchise == null
          ? DetailErrorState(onRetry: _load)
          : TgRefreshIndicator(
              onRefresh: _load,
              child: ContentFrame(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    GameFranchiseBanner(franchise: franchise),
                    const SizedBox(height: 24),
                    Text(
                      context.t('common:titleCount', {
                        'count': franchise.games.length,
                      }),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (franchise.games.isEmpty)
                      EmptyBlock(
                        icon: HugeIcons.strokeRoundedGameController01,
                        title: context.t('common:noResults'),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: AdaptiveGridDelegate(
                          context: context,
                          maxCrossAxisExtent: 150,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: franchise.games.length,
                        itemBuilder: (context, index) {
                          final game = franchise.games[index];
                          return GameFranchiseCard(
                            game: game,
                            onTap: () => _openGame(game),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
