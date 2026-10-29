import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';

import '../components/franchise/book_franchise_banner.dart';
import '../components/franchise/book_franchise_card.dart';
import '../components/details/detail_widgets.dart';
import '../components/layout/adaptive_grid_delegate.dart';
import '../components/layout/content_frame.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/book_detail.dart';
import '../models/media_type.dart';
import '../services/book_service.dart';
import 'media_detail_page.dart';

const _siteUrl = 'https://trackgeek.net';

class BookFranchisePage extends StatefulWidget {
  const BookFranchisePage({super.key, required this.slug, required this.env});

  final String slug;
  final MediaDetailEnv env;

  @override
  State<BookFranchisePage> createState() => _BookFranchisePageState();
}

class _BookFranchisePageState extends State<BookFranchisePage> {
  late final BookService _books;
  BookFranchise? _franchise;
  var _loading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _books = BookService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    final language = L10nScope.of(context).language;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final franchise = await _books.franchise(widget.slug, language: language);
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

  void _openBook(FranchiseBook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: MediaType.book,
          id: '${book.hardcoverId}',
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
                  text: '$_siteUrl/book/franchises/${franchise.slug}',
                ),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    BookFranchiseBanner(franchise: franchise),
                    const SizedBox(height: 24),
                    Text(
                      context.t('common:titleCount', {
                        'count': franchise.books.length,
                      }),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (franchise.books.isEmpty)
                      EmptyBlock(
                        icon: HugeIcons.strokeRoundedBook02,
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
                        itemCount: franchise.books.length,
                        itemBuilder: (context, index) {
                          final book = franchise.books[index];
                          return BookFranchiseCard(
                            book: book,
                            onTap: () => _openBook(book),
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
