import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

MarkdownStyleSheet feedMarkdownStyleSheet(ThemeData theme) {
  final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
    color: theme.colorScheme.onSurface,
    height: 1.4,
  );
  return MarkdownStyleSheet.fromTheme(theme).copyWith(
    p: bodyStyle,
    a: bodyStyle?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    ),
    strong: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
    em: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
    del: bodyStyle?.copyWith(decoration: TextDecoration.lineThrough),
    code: bodyStyle?.copyWith(
      fontFamily: 'monospace',
      fontSize: 12,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    ),
    codeblockDecoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: theme.colorScheme.outlineVariant, width: 2),
      ),
    ),
    blockquote: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
    h1: bodyStyle?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
    h2: bodyStyle?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
    h3: bodyStyle?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
    h4: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
    h5: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
    h6: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
    listBullet: bodyStyle,
  );
}
