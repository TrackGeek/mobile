import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/feed_entry.dart';
import '../../utils/strings.dart';
import 'feed_item_card.dart';
import 'feed_markdown.dart';
import 'feed_reactions.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';

const postMaxLength = 20000;
const _collapseLength = 900;

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.entry,
    required this.currentUserId,
    this.onMediaTap,
    this.onUserTap,
    this.onTitleLinkTap,
    this.onReact,
    this.isReacting = false,
    this.onUpdate,
    this.onDelete,
  });

  final FeedEntry entry;
  final String currentUserId;
  final VoidCallback? onMediaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onTitleLinkTap;
  final void Function(String emoji, FeedReaction? currentReaction)? onReact;
  final bool isReacting;
  final Future<void> Function(String postId, String content)? onUpdate;
  final Future<void> Function(String postId)? onDelete;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _expanded = false;
  bool _revealed = false;
  bool _busy = false;
  String? _draft;

  bool get _isAuthor =>
      widget.entry.authorId != null &&
      widget.entry.authorId == widget.currentUserId;

  Future<void> _confirmDelete() async {
    final postId = widget.entry.postId;
    if (postId == null || widget.onDelete == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('feed:postDeleteConfirmTitle')),
        content: Text(context.t('feed:postDeleteConfirmDescription')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.t('common:cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.t('feed:removeConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDelete!(postId);
      if (mounted) {
        HapticsHelper.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('feed:postDeleteSuccess'))),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        HapticsHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('feed:postDeleteError'))),
        );
      }
    }
  }

  Future<void> _save() async {
    final postId = widget.entry.postId;
    final content = _draft?.trim();
    if (postId == null || content == null || content.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.onUpdate!(postId, content);
      if (mounted) {
        setState(() {
          _draft = null;
          _busy = false;
        });
        HapticsHelper.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('feed:postUpdateSuccess'))),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        HapticsHelper.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('feed:postUpdateError'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final content = entry.content ?? '';
    final isLong = content.length > _collapseLength;
    final visible = isLong && !_expanded
        ? '${content.substring(0, _collapseLength)}…'
        : content;
    final locale = L10nScope.of(context).language;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onUserTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          FeedAvatar(
                            name: entry.profile.name,
                            avatarUrl: entry.profile.avatarUrl,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMd(locale)
                                      .add_jm()
                                      .format(entry.time.toLocal()),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isAuthor) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      size: 16,
                    ),
                    tooltip: context.t('feed:edit'),
                    onPressed: _draft != null || _busy
                        ? null
                        : () => setState(() => _draft = content),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedTrash,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: context.t('common:delete'),
                    onPressed: _busy ? null : _confirmDelete,
                  ),
                ],
              ],
            ),
            if (widget.onTitleLinkTap != null || entry.mediaTitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 2),
                child: InkWell(
                  onTap: widget.onTitleLinkTap,
                  child: Text(
                    entry.mediaTitle.orPlaceholder(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (_draft != null) ...[
              TextField(
                controller: TextEditingController(text: _draft),
                onChanged: (v) => _draft = v,
                maxLength: postMaxLength,
                maxLines: null,
                minLines: 4,
                enabled: !_busy,
                autofocus: true,
                decoration: const InputDecoration(counterText: ''),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _draft = null),
                    child: Text(context.t('common:cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _busy || (_draft?.trim().isEmpty ?? true)
                        ? null
                        : _save,
                    child: Text(context.t('common:save')),
                  ),
                ],
              ),
            ] else if (entry.isSpoiler && !_revealed)
              _SpoilerBox(
                content: visible,
                onReveal: () => setState(() => _revealed = true),
              )
            else ...[
              MarkdownBody(
                data: visible,
                styleSheet: feedMarkdownStyleSheet(theme),
              ),
              if (isLong)
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      context.t(
                        _expanded ? 'common:showLess' : 'common:showMore',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
            if (entry.media != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: widget.onMediaTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surfaceContainerHigh,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 64,
                          child: entry.coverUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: ImageFiltered(
                                    enabled: entry.isAdult,
                                    imageFilter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: SmoothImage(
                                      url: entry.coverUrl,
                                      error: const _MediaFallback(),
                                    ),
                                  ),
                                )
                              : const _MediaFallback(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.mediaTitle.orPlaceholder(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FeedReactions(
                currentUserId: widget.currentUserId,
                activityId: entry.activityId,
                reactions: entry.reactions,
                likes: entry.likes,
                onReact: widget.onReact,
                isReacting: widget.isReacting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: HugeIcon(icon: HugeIcons.strokeRoundedActivity01, size: 20),
      ),
    );
  }
}

class _SpoilerBox extends StatelessWidget {
  const _SpoilerBox({required this.content, required this.onReveal});

  final String content;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onReveal,
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          ClipRect(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: IgnorePointer(
                  child: MarkdownBody(
                    data: content,
                    styleSheet: feedMarkdownStyleSheet(theme),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerHigh,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedEyeOff,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.t('comments:spoilerReveal'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
