import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/watch_providers.dart';
import '../../services/api_client.dart';
import '../../services/settings_service.dart';
import 'detail_widgets.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';

typedef WatchProvidersLoader = Future<WatchProviders> Function(
  int tmdbId, {
  String? region,
  String language,
  Future<void>? cancelWhen,
});

typedef WatchProviderRegionsLoader =
    Future<List<WatchProviderRegion>> Function({
      String language,
      Future<void>? cancelWhen,
    });

const _regionPrefsKey = 'trackgeek.watchRegion';
const _defaultRegion = 'US';
final _regionCodePattern = RegExp(r'^[A-Z]{2}$');

const _offerConfig =
    <String, ({String label, List<List<dynamic>> icon, Color color})>{
      'flatrate': (
        label: 'library:watchProviders.stream',
        icon: HugeIcons.strokeRoundedPlayCircle,
        color: Color(0xFF10B981),
      ),
      'free': (
        label: 'library:watchProviders.free',
        icon: HugeIcons.strokeRoundedGift,
        color: Color(0xFFE3A008),
      ),
      'ads': (
        label: 'library:watchProviders.ads',
        icon: HugeIcons.strokeRoundedTvMinimal,
        color: Color(0xFF9C4EDD),
      ),
      'rent': (
        label: 'library:watchProviders.rent',
        icon: HugeIcons.strokeRoundedTicket02,
        color: Color(0xFF4661E6),
      ),
      'buy': (
        label: 'library:watchProviders.buy',
        icon: HugeIcons.strokeRoundedShoppingCart01,
        color: Color(0xFFE5484D),
      ),
    };

String flagEmoji(String code) => String.fromCharCodes([
  for (final unit in code.toUpperCase().codeUnits)
    if (unit >= 65 && unit <= 90) 127397 + unit,
]);

class WatchProvidersSection extends StatefulWidget {
  const WatchProvidersSection({
    super.key,
    required this.providers,
    required this.regions,
    required this.api,
    required this.session,
    required this.tmdbId,
  });

  final WatchProvidersLoader providers;
  final WatchProviderRegionsLoader regions;
  final ApiClient api;
  final SessionController session;
  final int tmdbId;

  @override
  State<WatchProvidersSection> createState() => _WatchProvidersSectionState();
}

class _WatchProvidersSectionState extends State<WatchProvidersSection> {
  late final SettingsService _settings;
  String? _region;
  WatchProviders? _providers;
  var _loading = true;
  var _error = false;
  var _savingRegion = false;
  List<WatchProviderRegion>? _regions;
  final _regionNames = <String, String>{};

  @override
  void initState() {
    super.initState();
    _settings = SettingsService(widget.api);
    _resolve();
  }

  Future<void> _resolve() async {
    final profileRegion = widget.session.user?.watchRegion?.toUpperCase();
    String region;
    if (profileRegion != null && _regionCodePattern.hasMatch(profileRegion)) {
      region = profileRegion;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_regionPrefsKey)?.toUpperCase();
      if (stored != null && _regionCodePattern.hasMatch(stored)) {
        region = stored;
      } else {
        final device = ui.PlatformDispatcher.instance.locale.countryCode
            ?.toUpperCase();
        region = device != null && _regionCodePattern.hasMatch(device)
            ? device
            : _defaultRegion;
      }
    }
    if (!mounted) return;
    setState(() => _region = region);
    await _loadProviders();
    unawaited(_loadRegions());
  }

  Future<void> _loadProviders() async {
    final region = _region;
    if (region == null) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final providers = await widget.providers(
        widget.tmdbId,
        region: region,
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _loadRegions() async {
    if (_regions != null) return;
    try {
      final regions = await widget.regions(
        language: L10nScope.of(context).language,
      );
      if (!mounted) return;
      setState(() {
        _regions = regions;
        _regionNames.addAll({for (final r in regions) r.code: r.name});
      });
    } catch (_) {}
  }

  String _regionName(String code) => _regionNames[code] ?? code;

  Future<void> _selectRegion(String code) async {
    final next = code.toUpperCase();
    if (!_regionCodePattern.hasMatch(next) || next == _region) return;
    setState(() {
      _region = next;
      _savingRegion = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionPrefsKey, next);
    if (widget.session.loggedIn) {
      try {
        await _settings.updateProfile({'watchRegion': next});
        unawaited(widget.session.refresh());
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _savingRegion = false);
    await _loadProviders();
  }

  Future<void> _openPicker() async {
    unawaited(_loadRegions());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _RegionPicker(
        selected: _region ?? _defaultRegion,
        regions: _regions,
        fallback: _providers?.availableRegions ?? const [],
        nameOf: _regionName,
        onSelect: (code) {
          HapticsHelper.selection();
          Navigator.of(sheetContext).pop();
          _selectRegion(code);
        },
      ),
    );
  }

  Future<void> _openJustWatch() async {
    final uri = Uri.tryParse('https://www.justwatch.com');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = _providers;
    final groups = [
      for (final offer in watchProviderOffers)
        if ((providers?.offer(offer) ?? const []).isNotEmpty)
          (offer: offer, items: providers!.offer(offer)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.t('library:watchProviders.title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _savingRegion ? null : _openPicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(flagEmoji(_region ?? _defaultRegion)),
                  const SizedBox(width: 6),
                  Text(_regionName(_region ?? _defaultRegion)),
                  const SizedBox(width: 4),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_region == null || _loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error)
          Center(
            child: TextButton(
              onPressed: _loadProviders,
              child: Text(context.t('common:tryAgain')),
            ),
          )
        else if (groups.isEmpty)
          EmptyBlock(
            icon: HugeIcons.strokeRoundedMonitorOff,
            title: context.t('library:watchProviders.notAvailable', {
              'country': _regionName(_region!),
            }),
            description: context.t(
              'library:watchProviders.notAvailableDescription',
            ),
          )
        else
          for (final group in groups) ...[
            _OfferGroup(offer: group.offer, items: group.items),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: _openJustWatch,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.t('library:watchProviders.attribution'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedLinkSquare02,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferGroup extends StatelessWidget {
  const _OfferGroup({required this.offer, required this.items});

  final String offer;
  final List<WatchProvider> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _offerConfig[offer]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: config.color.withValues(alpha: 0.15),
                  border: Border.all(
                    color: config.color.withValues(alpha: 0.35),
                  ),
                ),
                child: HugeIcon(
                  icon: config.icon,
                  size: 16,
                  color: config.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.t(config.label),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final provider in items) _ProviderTile(provider: provider),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.provider});

  final WatchProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = provider.logoUrl;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                color: theme.colorScheme.surface,
              ),
              child: logo == null || logo.isEmpty
                  ? Center(
                      child: Text(
                        provider.name.length >= 2
                            ? provider.name.substring(0, 2).toUpperCase()
                            : provider.name.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : SmoothImage(url: logo),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 12,
              height: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionPicker extends StatefulWidget {
  const _RegionPicker({
    required this.selected,
    required this.regions,
    required this.fallback,
    required this.nameOf,
    required this.onSelect,
  });

  final String selected;
  final List<WatchProviderRegion>? regions;
  final List<String> fallback;
  final String Function(String code) nameOf;
  final void Function(String code) onSelect;

  @override
  State<_RegionPicker> createState() => _RegionPickerState();
}

class _RegionPickerState extends State<_RegionPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String code, String name})>[];
    final apiRegions = widget.regions;
    if (apiRegions != null && apiRegions.isNotEmpty) {
      items.addAll([
        for (final r in apiRegions)
          (code: r.code, name: r.name.isNotEmpty ? r.name : r.nativeName),
      ]);
    } else {
      items.addAll([
        for (final code in {widget.selected, ...widget.fallback})
          (code: code, name: widget.nameOf(code)),
      ]);
    }
    items.sort((a, b) => a.name.compareTo(b.name));
    final query = _query.text.trim().toLowerCase();
    final filtered = [
      for (final item in items)
        if (query.isEmpty ||
            item.name.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query))
          item,
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: context.t('library:watchProviders.searchCountry'),
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(context.t('common:noResults')))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            dense: true,
                            leading: Text(
                              flagEmoji(item.code),
                              style: theme.textTheme.titleMedium,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: item.code == widget.selected
                                ? HugeIcon(
                                    icon: HugeIcons.strokeRoundedTick02,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () => widget.onSelect(item.code),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
