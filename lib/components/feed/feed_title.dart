import 'package:flutter/material.dart';

import '../../l10n/l10n_context.dart';

class FeedTitle extends StatelessWidget {
  const FeedTitle({
    super.key,
    required this.titleKey,
    this.values,
    this.onLinkTap,
    this.style,
    this.highlightStyle,
    this.capitalize = true,
  });

  final String titleKey;
  final Map<String, Object>? values;
  final VoidCallback? onLinkTap;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final bool capitalize;

  static final _nestedT = RegExp(
    r'\$t\(([a-zA-Z]+):([^,\s]+),\s*\{"count":\s*(\d+)\}\)',
  );

  String _resolve(BuildContext context) {
    var text = context.t(titleKey, values ?? const {});
    text = text.replaceAllMapped(
      _nestedT,
      (m) => context.t('${m[1]}:${m[2]}', {'count': int.parse(m[3]!)}),
    );
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle =
        style ??
        theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        );
    final strongStyle =
        highlightStyle ??
        baseStyle?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        );

    final resolved = _resolve(context);
    final parts = resolved.split(RegExp(r'(<strong>|</strong>)'));
    final spans = <InlineSpan>[];
    var bold = false;
    var capitalized = false;
    for (final part in parts) {
      if (part == '<strong>') {
        bold = true;
        continue;
      }
      if (part == '</strong>') {
        bold = false;
        continue;
      }
      if (part.isEmpty) continue;
      var text = part;
      if (!capitalized && capitalize) {
        text = text[0].toUpperCase() + text.substring(1);
        capitalized = true;
      }
      if (bold) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onLinkTap,
              child: Text(text, style: strongStyle),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: text, style: baseStyle));
      }
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
