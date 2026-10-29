import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';

class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.busy,
    this.onPressed,
  });

  final bool isFollowing;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: busy ? null : onPressed,
    icon: busy
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : HugeIcon(
            icon: isFollowing
                ? HugeIcons.strokeRoundedUserRemove01
                : HugeIcons.strokeRoundedUserAdd01,
            size: 14,
          ),
    label: Text(
      context.t(isFollowing ? 'user:unfollow' : 'user:follow'),
      style: const TextStyle(fontSize: 12),
    ),
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
