import 'package:flutter/material.dart';

import '../../models/book_detail.dart';
import '../details/detail_widgets.dart';

class BookFranchiseCard extends StatelessWidget {
  const BookFranchiseCard({super.key, required this.book, required this.onTap});

  final FranchiseBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverArt(url: book.imageUrl),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
