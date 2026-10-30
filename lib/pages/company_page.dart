import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/company/works_section.dart';
import '../components/details/detail_widgets.dart';
import '../components/layout/content_frame.dart';
import '../l10n/l10n_context.dart';
import '../models/api_exception.dart';
import '../models/company.dart';
import '../models/media_type.dart';
import '../services/company_service.dart';
import '../utils/social_links.dart';
import 'media_detail_page.dart';

const _siteUrl = 'https://trackgeek.net';
const _clampLength = 480;

const _mediaLabelKeys = {
  MediaType.movie: 'library:productionCompanies',
  MediaType.tv: 'library:productionCompanies',
  MediaType.anime: 'library:studios',
  MediaType.game: 'library:developers',
};

class CompanyPage extends StatefulWidget {
  const CompanyPage({
    super.key,
    required this.type,
    required this.id,
    required this.env,
  });

  final MediaType type;
  final String id;
  final MediaDetailEnv env;

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late final CompanyService _companies;
  Company? _company;
  var _loading = true;
  ApiException? _error;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _companies = CompanyService(widget.env.api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final company = await _companies.company(
        widget.type,
        widget.id,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _company = company;
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openWork(CompanyWork work) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => mediaDetailPage(
          type: widget.type,
          id: '${work.id}',
          details: widget.env.details,
          env: widget.env,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final company = _company;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          company?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (company != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedShare08,
                size: 20,
              ),
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: '$_siteUrl/${widget.type.slug}/company/${company.id}',
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || company == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _load,
                    child: Text(context.t('common:tryAgain')),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ContentFrame(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  children: [
                    _hero(company),
                    if (company.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _description(company),
                    ],
                    if (company.alsoKnownAs.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      DetailSection(
                        title: context.t('library:alsoKnownAs'),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final alias in company.alsoKnownAs)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                                child: Text(
                                  alias,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    CompanyWorksSection(
                      works: company.works,
                      onOpenWork: _openWork,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _hero(Company company) {
    final theme = Theme.of(context);
    final founded = company.foundedYear;
    final links = <({String key, String href, String asset, String label})>[
      if (company.homepage?.isNotEmpty == true)
        (key: 'homepage', href: company.homepage!, asset: '', label: ''),
      for (final link in company.external)
        (
          key: link.url,
          href: link.url,
          asset: resolveLink(link.url).asset,
          label: link.name,
        ),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: company.bannerUrl != null
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.45),
                          BlendMode.darken,
                        ),
                        child: Image.network(
                          company.bannerUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    ),
                    child: company.logoUrl?.isNotEmpty == true
                        ? Image.network(
                            company.logoUrl!,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => HugeIcon(
                              icon: HugeIcons.strokeRoundedBuilding03,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedBuilding03,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context
                        .t(
                          _mediaLabelKeys[company.mediaType] ??
                              'library:studios',
                        )
                        .toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    company.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (founded != null)
                        _meta(
                          theme,
                          HugeIcons.strokeRoundedCalendar01,
                          '${context.t('library:founded')} $founded',
                        ),
                      if (company.headquarters?.isNotEmpty == true)
                        _meta(
                          theme,
                          HugeIcons.strokeRoundedLocation01,
                          company.headquarters!,
                        ),
                      if (company.originCountry?.isNotEmpty == true)
                        _meta(
                          theme,
                          HugeIcons.strokeRoundedEarth,
                          company.originCountry!,
                        ),
                      _meta(
                        theme,
                        HugeIcons.strokeRoundedLayers01,
                        context.t('common:titleCount', {
                          'count': company.totalWorks,
                        }),
                      ),
                    ],
                  ),
                  if (links.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final link in links)
                          InkWell(
                            onTap: () => _openUrl(link.href),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              child: Center(
                                child: link.asset.isEmpty
                                    ? HugeIcon(
                                        icon: HugeIcons.strokeRoundedLink01,
                                        size: 18,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      )
                                    : SvgPicture.asset(
                                        link.asset,
                                        width: 18,
                                        height: 18,
                                        colorFilter: ColorFilter.mode(
                                          theme.colorScheme.onSurfaceVariant,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(ThemeData theme, List<List<dynamic>> icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _description(Company company) {
    final theme = Theme.of(context);
    final description = company.description!;
    final isLong = description.length > _clampLength;
    final text = isLong && !_expanded
        ? '${description.substring(0, _clampLength).trimRight()}…'
        : description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('library:companyAbout'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (isLong)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: HugeIcon(
              icon: _expanded
                  ? HugeIcons.strokeRoundedArrowUp01
                  : HugeIcons.strokeRoundedArrowDown01,
              size: 14,
            ),
            label: Text(
              context.t(_expanded ? 'common:showLess' : 'common:showMore'),
            ),
          ),
      ],
    );
  }
}
