import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../controllers/session_controller.dart';
import '../../l10n/l10n_context.dart';
import '../../models/api_exception.dart';
import '../../models/follow.dart';
import '../../models/paginated_page.dart';
import '../../services/user_service.dart';
import 'follow_button.dart';
import 'user_widgets.dart';
import '../layout/tg_refresh_indicator.dart';
import '../layout/bottom_padding.dart';

class UserFollowsTab extends StatefulWidget {
  const UserFollowsTab({
    super.key,
    required this.userId,
    required this.kind,
    required this.session,
    required this.users,
    this.onOpenUser,
    this.onChanged,
  });

  final String userId;
  final String kind;
  final SessionController session;
  final UserService users;
  final void Function(String username)? onOpenUser;
  final VoidCallback? onChanged;

  @override
  State<UserFollowsTab> createState() => _UserFollowsTabState();
}

class _UserFollowsTabState extends State<UserFollowsTab>
    with AutomaticKeepAliveClientMixin {
  final _entries = <FollowEntry>[];
  final _statuses = <String, bool>{};
  final _busy = <String>{};
  bool _loading = false;
  bool _loadingMore = false;
  bool _loaded = false;
  Object? _error;
  int _page = 0;
  bool _hasNext = false;

  @override
  bool get wantKeepAlive => true;

  String get _language => L10nScope.read(context).language;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(1);
      _entries
        ..clear()
        ..addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
      _loaded = true;
      await _loadStatuses();
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<PaginatedPage<FollowEntry>> _fetch(int page) =>
      widget.kind == 'followers'
      ? widget.users.followers(widget.userId, page: page, language: _language)
      : widget.users.following(widget.userId, page: page, language: _language);

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_page + 1);
      _entries.addAll(page.items);
      _page = page.inPage;
      _hasNext = page.hasNextPage;
      await _loadStatuses();
    } catch (_) {
      // keep loaded entries; retry on next scroll
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadStatuses() async {
    final viewer = widget.session.user;
    if (viewer == null) return;
    final pending = <String>[];
    for (final entry in _entries) {
      final user = widget.kind == 'followers'
          ? entry.follower
          : entry.following;
      if (user != null &&
          user.id != viewer.id &&
          !_statuses.containsKey(user.id)) {
        pending.add(user.username);
      }
    }
    for (final username in pending) {
      try {
        final status = await widget.users.followStatusDetails(
          username,
          language: _language,
        );
        if (!mounted) return;
        final user = _users().firstWhere(
          (u) => u.username == username,
          orElse: () => const FollowUser(id: '', name: '', username: ''),
        );
        if (user.id.isNotEmpty) _statuses[user.id] = status.isFollowing;
      } on ApiException {
        // best-effort status; absence renders follow button as not following
      }
    }
    if (mounted && pending.isNotEmpty) setState(() {});
  }

  List<FollowUser> _users() => [
    for (final entry in _entries)
      ?(widget.kind == 'followers' ? entry.follower : entry.following),
  ];

  Future<void> _toggle(FollowUser user) async {
    if (!_busy.add(user.id)) return;
    final wasFollowing = _statuses[user.id] ?? false;
    setState(() => _statuses[user.id] = !wasFollowing);
    try {
      if (wasFollowing) {
        await widget.users.unfollow(user.id);
      } else {
        await widget.users.follow(user.id);
      }
      widget.onChanged?.call();
    } catch (_) {
      if (mounted) setState(() => _statuses[user.id] = wasFollowing);
    } finally {
      _busy.remove(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _entries.isEmpty) {
      return UserError(onRetry: _load);
    }
    final users = _users();
    if (_loaded && users.isEmpty) {
      return widget.kind == 'followers'
          ? UserEmpty(
              icon: HugeIcons.strokeRoundedUserGroup,
              title: context.t('user:noFollowers'),
              description: context.t('user:noFollowersDescription'),
            )
          : UserEmpty(
              icon: HugeIcons.strokeRoundedUserGroup,
              title: context.t('user:noFollowing'),
              description: context.t('user:noFollowingDescription'),
            );
    }
    final viewer = widget.session.user;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: TgRefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16)
              .copyWith(bottom: BottomPadding.of(context)),
          itemCount: users.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index >= users.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final user = users[index];
            final isSelf = viewer?.id == user.id;
            return InkWell(
              onTap: () => widget.onOpenUser?.call(user.username),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    UserAvatar(name: user.name, avatarUrl: user.avatarUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (!isSelf && viewer != null)
                      FollowButton(
                        isFollowing: _statuses[user.id] ?? false,
                        busy: _busy.contains(user.id),
                        onPressed: () => _toggle(user),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
