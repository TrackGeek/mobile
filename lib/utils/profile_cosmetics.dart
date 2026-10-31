import 'package:flutter/material.dart';

const profileGradientPrefix = 'gradient:';

const profileGradients = <String, List<Color>>{
  'dusk': [Color(0xFFF43F5E), Color(0xFF8B5CF6)],
  'oceanic': [Color(0xFF06B6D4), Color(0xFF2563EB)],
  'sunrise': [Color(0xFFF59E0B), Color(0xFFFB7185)],
  'nebula': [Color(0xFF8B5CF6), Color(0xFFD946EF)],
  'aurora_flow': [Color(0xFF34D399), Color(0xFF22D3EE), Color(0xFFA78BFA)],
  'prism': [
    Color(0xFFF43F5E),
    Color(0xFFF59E0B),
    Color(0xFF34D399),
    Color(0xFF22D3EE),
    Color(0xFF8B5CF6),
  ],
};

class AvatarFrameStyle {
  const AvatarFrameStyle({
    required this.color,
    this.width = 2,
    this.glow = const [],
  });

  final Color color;
  final double width;
  final List<BoxShadow> glow;
}

const avatarFrameStyles = <String, AvatarFrameStyle>{
  'glow': AvatarFrameStyle(
    color: Color(0xFF34D399),
    glow: [BoxShadow(color: Color(0xCC34D399), blurRadius: 14)],
  ),
  'neon': AvatarFrameStyle(
    color: Color(0xFFE879F9),
    glow: [BoxShadow(color: Color(0xE6E879F9), blurRadius: 16)],
  ),
  'gold_ring': AvatarFrameStyle(
    color: Color(0xFFFBBF24),
    width: 3,
    glow: [BoxShadow(color: Color(0x99FBBF24), blurRadius: 10)],
  ),
  'rose_petals': AvatarFrameStyle(
    color: Color(0xFFFDA4AF),
    glow: [BoxShadow(color: Color(0xB3FDA4AF), blurRadius: 12)],
  ),
  'aurora': AvatarFrameStyle(
    color: Color(0xFF67E8F9),
    glow: [
      BoxShadow(color: Color(0xB367E8F9), blurRadius: 10),
      BoxShadow(color: Color(0x99A78BFA), blurRadius: 22),
    ],
  ),
  'obsidian_ring': AvatarFrameStyle(
    color: Color(0xFF3F3F46),
    width: 3,
    glow: [BoxShadow(color: Color(0xE618181B), blurRadius: 12)],
  ),
};

abstract final class BannerEffects {
  static BoxDecoration decoration(String key) {
    return switch (key) {
      'gradient_wave' => const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x4010B981), Colors.transparent, Color(0x4010B981)],
        ),
      ),
      'aurora_sky' => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0x408B5CF6), Color(0x3322D3EE), Color(0x4034D399)],
        ),
      ),
      'vignette_glow' => const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.4,
          colors: [Colors.transparent, Color(0x59000000)],
          stops: [0.6, 1.0],
        ),
      ),
      'scanlines' => const BoxDecoration(),
      'particles' => const BoxDecoration(),
      _ => const BoxDecoration(),
    };
  }

  static CustomPainter? painter(String key) {
    return switch (key) {
      'particles' => _ParticlesPainter(),
      'scanlines' => _ScanlinesPainter(),
      _ => null,
    };
  }
}

class _ParticlesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x40FFFFFF);
    const spacing = 18.0;
    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0FFFFFFF);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

bool isGradientColor(String? value) =>
    value?.startsWith(profileGradientPrefix) ?? false;

String gradientKeyFromValue(String value) =>
    value.substring(profileGradientPrefix.length);

Color? parseHexColor(String? value) {
  if (value == null) return null;
  var hex = value.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(parsed);
}

BoxDecoration profileColorDecoration(String? value, {double radius = 10}) {
  if (isGradientColor(value)) {
    final colors = profileGradients[gradientKeyFromValue(value!)];
    if (colors != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      );
    }
  }
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: parseHexColor(value),
  );
}

Color? profileAccentColor(String? value) {
  if (isGradientColor(value)) {
    return profileGradients[gradientKeyFromValue(value!)]?.first;
  }
  return parseHexColor(value);
}

ThemeData profileTheme(ThemeData base, String? value) {
  final accent = profileAccentColor(value);
  if (accent == null) return base;
  final hsl = HSLColor.fromColor(accent);
  final primary = hsl
      .withLightness(hsl.lightness.clamp(0.62, 0.8))
      .withSaturation(hsl.saturation.clamp(0.0, 0.9))
      .toColor();
  final onPrimary = primary.computeLuminance() > 0.4
      ? const Color(0xFF101417)
      : Colors.white;
  Color tint(Color c, double t) =>
      Color.alphaBlend(accent.withValues(alpha: t), c);
  final scheme = base.colorScheme;
  final background = tint(scheme.surface, 0.06);
  final card = tint(scheme.surfaceContainerLow, 0.08);
  final raised = tint(scheme.surfaceContainerHigh, 0.1);
  final overlay = tint(scheme.surfaceContainerHighest, 0.12);
  final container = tint(scheme.surface, 0.28);
  final onContainer = hsl.withLightness(0.88).toColor();
  final themed = scheme.copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: container,
    onPrimaryContainer: onContainer,
    secondaryContainer: container,
    onSecondaryContainer: onContainer,
    tertiary: primary,
    surface: background,
    surfaceContainerLowest: background,
    surfaceContainerLow: card,
    surfaceContainer: card,
    surfaceContainerHigh: raised,
    surfaceContainerHighest: overlay,
  );
  return base.copyWith(
    colorScheme: themed,
    scaffoldBackgroundColor: background,
    appBarTheme: base.appBarTheme.copyWith(backgroundColor: background),
    cardTheme: base.cardTheme.copyWith(color: card),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: raised,
      selectedColor: container,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      fillColor: raised,
      focusedBorder:
          (base.inputDecorationTheme.focusedBorder as OutlineInputBorder?)
              ?.copyWith(borderSide: BorderSide(color: primary, width: 1.5)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        foregroundColor: WidgetStatePropertyAll(primary),
      ),
    ),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: primary,
      linearTrackColor: raised,
      circularTrackColor: raised,
    ),
    popupMenuTheme: base.popupMenuTheme.copyWith(color: overlay),
    textSelectionTheme: base.textSelectionTheme.copyWith(
      cursorColor: primary,
      selectionHandleColor: primary,
    ),
  );
}
