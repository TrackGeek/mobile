import 'package:flutter/material.dart';

abstract final class TgColors {
  static const background = Color(0xFF0B1012);
  static const card = Color(0xFF141C1F);
  static const primary = Color(0xFF5CDEB0);
  static const primaryForeground = Color(0xFF062C20);
  static const secondary = Color(0xFFAAC9BE);
  static const secondaryForeground = Color(0xFF102E26);
  static const accent = Color(0xFF31B78C);
  static const muted = Color(0xFF202B2F);
  static const mutedForeground = Color(0xFFA5B4B7);
  static const foreground = Color(0xFFF0F5F3);
  static const border = Color(0xFF344348);
  static const destructive = Color(0xFFFF8C8C);
}

ThemeData trackGeekTheme() {
  const scheme = ColorScheme.dark(
    primary: TgColors.primary,
    onPrimary: TgColors.primaryForeground,
    primaryContainer: Color(0xFF164536),
    onPrimaryContainer: Color(0xFFB1F5D9),
    secondary: TgColors.secondary,
    onSecondary: TgColors.secondaryForeground,
    tertiary: TgColors.accent,
    error: TgColors.destructive,
    onError: Color(0xFF4C1015),
    surface: TgColors.background,
    surfaceContainerLowest: TgColors.background,
    surfaceContainerLow: TgColors.card,
    surfaceContainer: TgColors.card,
    surfaceContainerHigh: TgColors.muted,
    surfaceContainerHighest: Color(0xFF2A373B),
    onSurface: TgColors.foreground,
    onSurfaceVariant: TgColors.mutedForeground,
    outline: TgColors.border,
    outlineVariant: Color(0xFF263338),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TgColors.background,
    fontFamily: 'Archivo',
  );
  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  const controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TgColors.background,
      foregroundColor: TgColors.foreground,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: TgColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF263338),
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TgColors.card,
      selectedColor: scheme.primaryContainer,
      side: const BorderSide(color: Color(0xFF344348)),
      labelStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
        fontSize: 13,
      ),
      shape: controlShape,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TgColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.mutedForeground,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF344348)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF344348)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TgColors.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        textStyle: const TextStyle(
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        side: const BorderSide(color: TgColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: TgColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Archivo',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? TgColors.primary
              : TgColors.mutedForeground,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: TgColors.background,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: const IconThemeData(color: TgColors.primary),
      unselectedIconTheme: const IconThemeData(color: TgColors.mutedForeground),
      selectedLabelTextStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.mutedForeground,
        fontSize: 12,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelColor: TgColors.primary,
      unselectedLabelColor: TgColors.mutedForeground,
      indicatorColor: TgColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
      ),
      overlayColor: WidgetStatePropertyAll(
        scheme.primary.withValues(alpha: 0.08),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TgColors.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: 760),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: TgColors.card,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: TgColors.muted,
      shape: controlShape,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: TgColors.muted,
      contentTextStyle: TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
      ),
      behavior: SnackBarBehavior.floating,
      shape: controlShape,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TgColors.primary,
      linearTrackColor: TgColors.muted,
      circularTrackColor: TgColors.muted,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: TgColors.primary,
      foregroundColor: TgColors.primaryForeground,
      elevation: 2,
      shape: rounded,
    ),
  );
}
