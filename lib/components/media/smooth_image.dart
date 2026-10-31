import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_fade/image_fade.dart';

class SmoothImage extends StatelessWidget {
  const SmoothImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment,
    this.error,
    this.transparent = false,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment? alignment;
  final Widget? error;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ImageFade(
      image: NetworkImage(url),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment ?? Alignment.center,
      duration: const Duration(milliseconds: 250),
      placeholder: Container(
        width: width,
        height: height,
        color: transparent
            ? Colors.transparent
            : theme.colorScheme.surfaceContainerHighest,
      ),
      errorBuilder: (context, _) =>
          error ??
          Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedImage01,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
    );
  }
}
