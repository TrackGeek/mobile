import 'package:flutter/material.dart';

class UserSearchSkeleton extends StatelessWidget {
  const UserSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 128, height: 14, color: color),
                const SizedBox(height: 6),
                Container(width: 80, height: 10, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserSearchSkeletonList extends StatelessWidget {
  const UserSearchSkeletonList({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: count,
      itemBuilder: (_, _) => const UserSearchSkeleton(),
    );
  }
}
