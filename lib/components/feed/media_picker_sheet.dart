import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../../models/attached_media.dart';
import '../../models/media_type.dart';
import '../../services/api_client.dart';
import '../../utils/content_types.dart';
import '../../utils/strings.dart';
import '../../controllers/session_controller.dart';
import '../media/smooth_image.dart';

const _typeIcons = <MediaType, List<List<dynamic>>>{
  MediaType.movie: HugeIcons.strokeRoundedClapperboard,
  MediaType.tv: HugeIcons.strokeRoundedTvMinimalPlay,
  MediaType.game: HugeIcons.strokeRoundedGameController01,
  MediaType.anime: HugeIcons.strokeRoundedMountain,
  MediaType.manga: HugeIcons.strokeRoundedLibraryBig,
  MediaType.book: HugeIcons.strokeRoundedBook01,
};

List<List<dynamic>> mediaTypeIcon(MediaType type) =>
    _typeIcons[type] ?? HugeIcons.strokeRoundedActivity01;

class MediaPickerSheet extends StatefulWidget {
  const MediaPickerSheet({
    super.key,
    required this.api,
    required this.session,
    required this.language,
  });

  final ApiClient api;
  final SessionController session;
  final String language;

  @override
  State<MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends State<MediaPickerSheet> {
  static const _resultLimit = 8;
  static const _debounce = Duration(milliseconds: 500);

  late MediaType _type;
  final _query = TextEditingController();
  Timer? _debouncer;
  List<AttachedMedia> _results = [];
  bool _loading = false;
  bool _error = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _type = visibleMediaTypes(widget.session.user).first;
    _query.addListener(_onQuery);
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery() {
    _debouncer?.cancel();
    _debouncer = Timer(_debounce, _search);
  }

  int? _externalIdFor(MediaType type, Map<String, dynamic> item) {
    final raw = switch (type) {
      MediaType.anime => item['malId'],
      MediaType.manga => item['anilistId'],
      MediaType.tv || MediaType.movie => item['tmdbId'],
      MediaType.game => item['igdbId'],
      MediaType.book => item['hardcoverId'],
    };
    return (raw as num?)?.toInt();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = false;
      });
      return;
    }
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final json = await widget.api.getJson(
        '${_type.slug}/search',
        query: {'query': query},
        language: widget.language,
      );
      if (id != _requestId) return;
      final envelope = json[_type.searchEnvelope];
      final items = envelope is Map<String, dynamic> ? envelope['items'] : null;
      final results = <AttachedMedia>[
        if (items is List)
          for (final item in items)
            if (item is Map<String, dynamic>)
              if (_externalIdFor(_type, item) case final externalId?
                  when externalId > 0)
                AttachedMedia(
                  type: _type,
                  externalId: externalId,
                  title: (item['title'] ?? item['name'] ?? '') as String,
                  imageUrl:
                      (item['imageUrl'] ??
                              item['posterUrl'] ??
                              item['coverUrl'])
                          as String?,
                ),
      ].take(_resultLimit).toList();
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (id != _requestId || !mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = visibleMediaTypes(widget.session.user).toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<MediaType>(
            initialValue: _type,
            decoration: InputDecoration(
              labelText: context.t('feed:postAttach'),
            ),
            items: [
              for (final type in visible)
                DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      HugeIcon(icon: mediaTypeIcon(type), size: 16),
                      const SizedBox(width: 8),
                      Text(context.t('common:types.${type.name}_other')),
                    ],
                  ),
                ),
            ],
            onChanged: (next) {
              if (next == null) return;
              setState(() {
                _type = next;
                _results = [];
              });
              _search();
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _query,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.t('feed:postAttachSearch'),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(10),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.t('common:somethingWentWrong'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: _search,
                          child: Text(context.t('common:tryAgain')),
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      context.t('common:noResults'),
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final media = _results[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: SizedBox(
                          width: 36,
                          height: 48,
                          child: media.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: SmoothImage(
                                    url: media.imageUrl!,
                                    error: _typeIcon(theme, _type),
                                  ),
                                )
                              : _typeIcon(theme, _type),
                        ),
                        title: Text(
                          media.title.orPlaceholder(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(media),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _typeIcon(ThemeData theme, MediaType type) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Center(
      child: HugeIcon(
        icon: mediaTypeIcon(type),
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class AttachedMediaChip extends StatelessWidget {
  const AttachedMediaChip({
    super.key,
    required this.media,
    required this.onRemove,
    this.disabled = false,
  });

  final AttachedMedia media;
  final VoidCallback onRemove;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 40,
            child: media.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SmoothImage(
                      url: media.imageUrl!,
                      error: _icon(theme),
                    ),
                  )
                : _icon(theme),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  media.title.orPlaceholder(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  context.t('common:types.${media.type.name}_other'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedX, size: 16),
            tooltip: context.t('feed:postAttachRemove'),
            onPressed: disabled ? null : onRemove,
          ),
        ],
      ),
    );
  }

  Widget _icon(ThemeData theme) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Center(
      child: HugeIcon(
        icon: mediaTypeIcon(media.type),
        size: 14,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
