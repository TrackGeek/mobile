import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n_context.dart';
import '../../models/profile_comment.dart';
import '../../services/comment_service.dart';
import '../feed/feed_markdown.dart';
import '../feed/feed_reactions.dart';
import 'user_widgets.dart';
import '../../utils/numbers.dart';

const _maxLength = 500;

class CommentsCard extends StatefulWidget {
  const CommentsCard({
    super.key,
    required this.target,
    required this.comments,
    required this.sessionUserId,
    required this.canModerate,
    this.onOpenUser,
    this.showTitle = true,
  });

  final CommentTarget target;
  final CommentService comments;
  final String? sessionUserId;
  final bool canModerate;
  final ValueChanged<String>? onOpenUser;
  final bool showTitle;

  @override
  State<CommentsCard> createState() => _CommentsCardState();
}

class _CommentsCardState extends State<CommentsCard> {
  final _items = <ProfileComment>[];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _language => L10nScope.read(context).language;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _items.clear();
      _page = 1;
    });
    try {
      final page = await widget.comments.comments(
        widget.target,
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _total = page.total ?? 0;
        _hasMore = page.hasNextPage;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.comments.comments(
        widget.target,
        page: _page + 1,
        language: _language,
      );
      if (!mounted) return;
      setState(() {
        _page += 1;
        _items.addAll(page.items);
        _total = page.total ?? 0;
        _hasMore = page.hasNextPage;
      });
    } catch (_) {
      // keep previous page
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _add(String content, bool isSpoiler, {String? parentId}) async {
    await widget.comments.addComment(
      widget.target,
      content: content,
      isSpoiler: isSpoiler,
      parentId: parentId,
    );
    await _load();
  }

  Future<void> _delete(String commentId) async {
    await widget.comments.deleteComment(commentId);
    await _load();
  }

  Future<void> _toggleReaction(ProfileComment comment, String emoji) async {
    final sessionUserId = widget.sessionUserId;
    if (sessionUserId == null) return;
    final current = comment.reactions
        .where((r) => r.userId == sessionUserId)
        .firstOrNull;
    await widget.comments.toggleReaction(
      comment.id,
      emoji: emoji,
      currentReaction: current,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canComment = widget.sessionUserId != null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canComment)
          _CommentForm(onSubmit: (content, spoiler) => _add(content, spoiler))
        else
          Text(
            context.t('comments:loginToComment'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          Text(
            canComment
                ? '${context.t('comments:empty')}\n${context.t('comments:emptyDescription')}'
                : context.t('comments:empty'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          for (final comment in _items)
            _CommentItem(
              comment: comment,
              sessionUserId: widget.sessionUserId,
              canModerate: widget.canModerate,
              onOpenUser: widget.onOpenUser,
              onAdd: (content, spoiler, parentId) =>
                  _add(content, spoiler, parentId: parentId),
              onDelete: _delete,
              onReaction: _toggleReaction,
            ),
          if (_hasMore)
            TextButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: _loadingMore
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.t('common:showMore')),
            ),
        ],
      ],
    );
    if (!widget.showTitle) return body;
    return UserCard(
      title:
          '${context.t('comments:title')}'
          '${_total > 0 ? ' (${context.t('comments:count', {'count': _total, 'formattedCount': _total.humanizedCount()})})' : ''}',
      icon: HugeIcons.strokeRoundedMessage01,
      child: body,
    );
  }
}

class _CommentForm extends StatefulWidget {
  const _CommentForm({
    required this.onSubmit,
    this.autoFocus = false,
    this.onCancel,
  });

  final Future<void> Function(String content, bool isSpoiler) onSubmit;
  final bool autoFocus;
  final VoidCallback? onCancel;

  @override
  State<_CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<_CommentForm> {
  final _controller = TextEditingController();
  bool _isSpoiler = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (_sending || content.isEmpty || content.length > _maxLength) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(content, _isSpoiler);
      _controller.clear();
      setState(() => _isSpoiler = false);
    } catch (_) {
      // keep input for retry
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: widget.autoFocus,
          maxLength: _maxLength,
          maxLines: 3,
          minLines: 2,
          enabled: !_sending,
          decoration: InputDecoration(
            hintText: context.t('comments:placeholder'),
            border: const OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: _isSpoiler,
                onChanged: _sending
                    ? null
                    : (value) => setState(() => _isSpoiler = value == true),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.t('comments:spoiler'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${_controller.text.trim().length}/$_maxLength',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            if (widget.onCancel != null)
              TextButton(
                onPressed: _sending ? null : widget.onCancel,
                child: Text(context.t('common:cancel')),
              ),
            FilledButton(
              onPressed: _sending || _controller.text.trim().isEmpty
                  ? null
                  : _submit,
              child: Text(context.t('common:send')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentItem extends StatefulWidget {
  const _CommentItem({
    required this.comment,
    required this.sessionUserId,
    required this.canModerate,
    required this.onAdd,
    required this.onDelete,
    required this.onReaction,
    this.onOpenUser,
  });

  final ProfileComment comment;
  final String? sessionUserId;
  final bool canModerate;
  final Future<void> Function(String, bool, String?) onAdd;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(ProfileComment, String) onReaction;
  final ValueChanged<String>? onOpenUser;

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _replying = false;
  bool _revealed = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comment = widget.comment;
    final canDelete =
        comment.userId == widget.sessionUserId || widget.canModerate;
    final counts = <String, int>{};
    for (final reaction in comment.reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    final current = widget.sessionUserId == null
        ? null
        : comment.reactions
              .where((r) => r.userId == widget.sessionUserId)
              .firstOrNull;
    final showBody = !comment.isSpoiler || _revealed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.onOpenUser == null
                ? null
                : () => widget.onOpenUser!(comment.user.username),
            child: UserAvatar(
              name: comment.user.username,
              avatarUrl: comment.user.avatarUrl,
              frame: comment.user.avatarFrame,
              size: 32,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: widget.onOpenUser == null
                            ? null
                            : () => widget.onOpenUser!(comment.user.username),
                        child: Text(
                          comment.user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (comment.user.level != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: Text(
                          context.t('xp:levelShort', {
                            'level': '${comment.user.level}',
                          }),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      comment.createdAt == null
                          ? ''
                          : ', ${DateFormat.yMd(L10nScope.of(context).language).add_jm().format(comment.createdAt!.toLocal())}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (canDelete)
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: _deleting
                            ? null
                            : () async {
                                setState(() => _deleting = true);
                                try {
                                  await widget.onDelete(comment.id);
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _deleting = false);
                                  }
                                }
                              },
                      ),
                  ],
                ),
                if (showBody)
                  MarkdownBody(
                    data: comment.content,
                    styleSheet: feedMarkdownStyleSheet(Theme.of(context)),
                  )
                else
                  InkWell(
                    onTap: () => setState(() => _revealed = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        color: theme.colorScheme.surfaceContainerHigh,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedEye,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.t('comments:spoilerReveal'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final emoji in quickReactions)
                      if ((counts[emoji] ?? 0) > 0 ||
                          current?.emoji == emoji ||
                          widget.sessionUserId != null)
                        InkWell(
                          onTap: widget.sessionUserId == null
                              ? null
                              : () => widget.onReaction(comment, emoji),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: current?.emoji == emoji
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                              color: current?.emoji == emoji
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    )
                                  : null,
                            ),
                            child: Text(
                              (counts[emoji] ?? 0) > 0
                                  ? '$emoji ${counts[emoji]!.humanizedCount()}'
                                  : emoji,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    if (widget.sessionUserId != null)
                      InkWell(
                        onTap: () => setState(() => _replying = !_replying),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedReply,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              context.t('common:reply'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_replying)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _CommentForm(
                      autoFocus: true,
                      onCancel: () => setState(() => _replying = false),
                      onSubmit: (content, spoiler) async {
                        await widget.onAdd(content, spoiler, comment.id);
                        if (mounted) setState(() => _replying = false);
                      },
                    ),
                  ),
                if (comment.replies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final reply in comment.replies)
                          _CommentItem(
                            comment: reply,
                            sessionUserId: widget.sessionUserId,
                            canModerate: widget.canModerate,
                            onAdd: widget.onAdd,
                            onDelete: widget.onDelete,
                            onReaction: widget.onReaction,
                            onOpenUser: widget.onOpenUser,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
