import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/l10n_context.dart';
import '../layout/content_frame.dart';
import '../../styles/tg_layout.dart';

const _biographyClampLength = 480;

class PersonBiography extends StatefulWidget {
  const PersonBiography({
    super.key,
    required this.biography,
    required this.name,
    required this.markdown,
    required this.onOpenLink,
  });

  final String biography;
  final String name;
  final bool markdown;
  final ValueChanged<String?> onOpenLink;

  @override
  State<PersonBiography> createState() => _BiographyState();
}

class _BiographyState extends State<PersonBiography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLong = widget.biography.length > _biographyClampLength;
    final bodyStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(bodyStyle.fontSize ?? 14) *
        (bodyStyle.height ?? 1.4);

    return ContentFrame(
      maxWidth: TgLayout.readingWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('library:biography'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.markdown)
            ClipRect(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isLong && !_expanded
                      ? lineHeight * 6
                      : double.infinity,
                ),
                child: MarkdownBody(
                  data: widget.biography,
                  onTapLink: (_, href, _) => widget.onOpenLink(href),
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: bodyStyle.copyWith(height: null),
                    a: bodyStyle.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    strong: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    em: bodyStyle.copyWith(fontStyle: FontStyle.italic),
                    del: bodyStyle.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                    code: bodyStyle.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    blockquote: bodyStyle.copyWith(fontStyle: FontStyle.italic),
                    h1: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    h2: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    h3: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    h4: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    h5: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                    h6: bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          else
            Text(
              isLong && !_expanded
                  ? '${widget.biography.substring(0, _biographyClampLength).trimRight()}…'
                  : widget.biography,
              style: bodyStyle.copyWith(height: 1.5),
            ),
          if (isLong) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: HugeIcon(
                icon: _expanded
                    ? HugeIcons.strokeRoundedArrowUp01
                    : HugeIcons.strokeRoundedArrowDown01,
                size: 16,
              ),
              label: Text(
                _expanded
                    ? context.t('common:showLess')
                    : context.t('common:showMore'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
