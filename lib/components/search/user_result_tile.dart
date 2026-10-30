import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';
import '../../controllers/session_controller.dart';
import '../../models/search_item.dart';
import '../../models/api_exception.dart';
import '../../services/user_service.dart';
import '../../utils/strings.dart';
import '../media/smooth_image.dart';
import '../../utils/haptics.dart';

class UserResultTile extends StatefulWidget {
  const UserResultTile({
    super.key,
    required this.item,
    required this.users,
    required this.session,
  });

  final SearchItem item;
  final UserService users;
  final SessionController session;

  @override
  State<UserResultTile> createState() => _UserResultTileState();
}

class _UserResultTileState extends State<UserResultTile> {
  bool? _following;
  bool _pending = false;

  bool get _isSelf => widget.session.user?.id == widget.item.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = widget.item.username;
    if (_isSelf || username == null) return;
    try {
      final following = await widget.users.followStatus(username);
      if (mounted) setState(() => _following = following);
    } on ApiException {
      return;
    }
  }

  Future<void> _toggle() async {
    final following = _following ?? false;
    setState(() => _pending = true);
    try {
      if (following) {
        await widget.users.unfollow(widget.item.id);
      } else {
        await widget.users.follow(widget.item.id);
      }
      if (!mounted) return;
      setState(() => _following = !following);
      HapticsHelper.success();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.t('user:followed'))));
    } on ApiException {
      HapticsHelper.error();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('user:followedError'))));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            child: item.imageUrl != null
                ? ClipOval(
                    child: SmoothImage(
                      url: item.imageUrl!,
                      width: 36,
                      height: 36,
                      error: Text(item.title.characters.first.toUpperCase()),
                    ),
                  )
                : Text(item.title.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.orPlaceholder(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (widget.session.user != null && !_isSelf)
            _following ?? false
                ? OutlinedButton(
                    onPressed: _pending ? null : _toggle,
                    child: Text(context.t('user:unfollow')),
                  )
                : FilledButton.tonal(
                    onPressed: _pending ? null : _toggle,
                    child: Text(context.t('user:follow')),
                  ),
        ],
      ),
    );
  }
}
