import 'package:flutter/material.dart';

import '../components/layout/content_frame.dart';
import '../styles/tg_layout.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';

import '../components/feed/feed_markdown.dart';
import '../components/feed/media_picker_sheet.dart';
import '../components/feed/post_card.dart';
import '../controllers/session_controller.dart';
import '../l10n/l10n_context.dart';
import '../models/attached_media.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';

class FeedComposerPage extends StatefulWidget {
  const FeedComposerPage({
    super.key,
    required this.api,
    required this.activities,
    required this.session,
  });

  final ApiClient api;
  final ActivityService activities;
  final SessionController session;

  @override
  State<FeedComposerPage> createState() => _FeedComposerPageState();
}

class _FeedComposerPageState extends State<FeedComposerPage> {
  final _content = TextEditingController();
  AttachedMedia? _media;
  bool _isSpoiler = false;
  bool _previewing = false;
  bool _pending = false;
  bool _error = false;

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  String get _trimmed => _content.text.trim();
  bool get _canSubmit =>
      _trimmed.isNotEmpty && _content.text.length <= postMaxLength && !_pending;

  Future<void> _attach() async {
    final language = L10nScope.of(context).language;
    final media = await showModalBottomSheet<AttachedMedia>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => MediaPickerSheet(
        api: widget.api,
        session: widget.session,
        language: language,
      ),
    );
    if (media != null && mounted) setState(() => _media = media);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _pending = true;
      _error = false;
    });
    try {
      await widget.activities.createPost(
        content: _trimmed,
        isSpoiler: _isSpoiler,
        mediaType: _media?.type,
        mediaExternalId: _media?.externalId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearLimit = _content.text.length >= postMaxLength * 0.9;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedX),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: HugeIcon(
                icon: _pending
                    ? HugeIcons.strokeRoundedLoading03
                    : HugeIcons.strokeRoundedSend,
                size: 16,
              ),
              label: Text(
                _pending
                    ? context.t('common:loading')
                    : _error
                    ? context.t('common:tryAgain')
                    : context.t('feed:postSubmit'),
              ),
            ),
          ),
        ],
      ),
      body: ContentFrame(
        maxWidth: TgLayout.readingWidth,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _previewing
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: MarkdownBody(
                          data: _trimmed,
                          styleSheet: feedMarkdownStyleSheet(theme),
                        ),
                      )
                    : TextField(
                        controller: _content,
                        maxLength: postMaxLength,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        enabled: !_pending,
                        decoration: InputDecoration(
                          hintText: context.t('feed:postPlaceholder'),
                          border: InputBorder.none,
                          filled: false,
                          counterText: '',
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: (_) {
                          if (_error) _error = false;
                          setState(() {});
                        },
                      ),
              ),
              if (_error)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlertCircle,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('feed:postError'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_media != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AttachedMediaChip(
                    media: _media!,
                    disabled: _pending,
                    onRemove: () => setState(() => _media = null),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    if (_media == null)
                      IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPaperclip,
                          size: 18,
                        ),
                        tooltip: context.t('feed:postAttach'),
                        onPressed: _pending ? null : _attach,
                      ),
                    TextButton.icon(
                      onPressed: _pending
                          ? null
                          : () => setState(() => _isSpoiler = !_isSpoiler),
                      icon: HugeIcon(
                        icon: _isSpoiler
                            ? HugeIcons.strokeRoundedCheckmarkSquare02
                            : HugeIcons.strokeRoundedSquare,
                        size: 16,
                      ),
                      label: Text(context.t('feed:spoiler')),
                      style: TextButton.styleFrom(
                        foregroundColor: _isSpoiler
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      icon: HugeIcon(
                        icon: _previewing
                            ? HugeIcons.strokeRoundedPencil
                            : HugeIcons.strokeRoundedEye,
                        size: 18,
                      ),
                      tooltip: _previewing
                          ? context.t('feed:edit')
                          : context.t('common:preview'),
                      onPressed: _trimmed.isEmpty || _pending
                          ? null
                          : () => setState(() => _previewing = !_previewing),
                    ),
                    if (_content.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (nearLimit)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedAlertCircle,
                                  size: 14,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            Text(
                              '${_content.text.length} / $postMaxLength',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: nearLimit
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
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
}
