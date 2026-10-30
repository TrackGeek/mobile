import 'package:flutter/material.dart';

abstract final class TgColors {
  static const background = Color(0xFF0B1012);
  static const card = Color(0xFF151E22);
  static const raised = Color(0xFF1F2A2E);
  static const overlay = Color(0xFF28343A);
  static const primary = Color(0xFF5CDEB0);
  static const primaryForeground = Color(0xFF062C20);
  static const primaryContainer = Color(0xFF164536);
  static const onPrimaryContainer = Color(0xFFB1F5D9);
  static const secondary = Color(0xFFAAC9BE);
  static const secondaryForeground = Color(0xFF102E26);
  static const accent = Color(0xFF31B78C);
  static const muted = Color(0xFF1F2A2E);
  static const mutedForeground = Color(0xFFB4C4C1);
  static const faint = Color(0xFF7C8F8C);
  static const foreground = Color(0xFFF0F5F3);
  static const borderSubtle = Color(0xFF243238);
  static const border = Color(0xFF3A4B50);
  static const destructive = Color(0xFFFF8C8C);
  static const scrim = Color(0x8A000000);
  static const onScrim = Color(0xFFFFFFFF);
  static const gold = Color(0xFFFBBF24);
}

abstract final class TgStatus {
  static const planning = Color(0xFF9C4EDD);
  static const active = Color(0xFF10B981);
  static const completed = Color(0xFFE3A008);
  static const info = Color(0xFF4661E6);
  static const danger = Color(0xFFE5484D);
}

abstract final class TgRadii {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;

  static final card = BorderRadius.circular(lg);
  static final control = BorderRadius.circular(md);
  static final chip = BorderRadius.circular(sm);
}

ThemeData trackGeekTheme() {
  const scheme = ColorScheme.dark(
    primary: TgColors.primary,
    onPrimary: TgColors.primaryForeground,
    primaryContainer: TgColors.primaryContainer,
    onPrimaryContainer: TgColors.onPrimaryContainer,
    secondary: TgColors.secondary,
    onSecondary: TgColors.secondaryForeground,
    secondaryContainer: TgColors.primaryContainer,
    onSecondaryContainer: TgColors.onPrimaryContainer,
    tertiary: TgColors.accent,
    error: TgColors.destructive,
    onError: Color(0xFF4C1015),
    surface: TgColors.background,
    surfaceContainerLowest: TgColors.background,
    surfaceContainerLow: TgColors.card,
    surfaceContainer: TgColors.card,
    surfaceContainerHigh: TgColors.raised,
    surfaceContainerHighest: TgColors.overlay,
    onSurface: TgColors.foreground,
    onSurfaceVariant: TgColors.mutedForeground,
    outline: TgColors.border,
    outlineVariant: TgColors.borderSubtle,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: TgColors.background,
    fontFamily: 'Archivo',
  );
  final rounded = RoundedRectangleBorder(borderRadius: TgRadii.card);
  final controlShape = RoundedRectangleBorder(borderRadius: TgRadii.control);
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
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.5),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: TgColors.mutedForeground,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
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
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: TgColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: TgRadii.card,
        side: const BorderSide(color: TgColors.borderSubtle),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: TgColors.borderSubtle,
      thickness: 1,
      space: 24,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TgColors.raised,
      selectedColor: scheme.primaryContainer,
      side: const BorderSide(color: TgColors.borderSubtle),
      labelStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.onPrimaryContainer,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      shape: controlShape,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TgColors.raised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(fontFamily: 'Archivo', color: TgColors.faint),
      labelStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.mutedForeground,
      ),
      border: OutlineInputBorder(
        borderRadius: TgRadii.control,
        borderSide: const BorderSide(color: TgColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TgRadii.control,
        borderSide: const BorderSide(color: TgColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TgRadii.control,
        borderSide: const BorderSide(color: TgColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: TgRadii.control,
        borderSide: const BorderSide(color: TgColors.destructive),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: TgColors.primary.withValues(alpha: 0.3),
      selectionHandleColor: TgColors.primary,
      cursorColor: TgColors.primary,
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
        foregroundColor: TgColors.foreground,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: controlShape,
        foregroundColor: TgColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Archivo',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: TgColors.mutedForeground,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: TgColors.mutedForeground,
      textColor: TgColors.foreground,
      titleTextStyle: TextStyle(
        fontFamily: 'Archivo',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: TgColors.foreground,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Archivo',
        fontSize: 13,
        color: TgColors.mutedForeground,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: TgColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? TgColors.primary
              : TgColors.mutedForeground,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Archivo',
          fontSize: 12,
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
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.mutedForeground,
        fontSize: 12,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: TgColors.borderSubtle,
      labelColor: TgColors.primary,
      unselectedLabelColor: TgColors.mutedForeground,
      indicatorColor: TgColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w500,
      ),
      overlayColor: WidgetStatePropertyAll(
        scheme.primary.withValues(alpha: 0.08),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: TgColors.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 760),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TgRadii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TgColors.overlay,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: TgColors.overlay,
      shape: controlShape,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: TgColors.overlay,
        borderRadius: TgRadii.chip,
        border: Border.all(color: TgColors.borderSubtle),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
        fontSize: 12,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TgColors.overlay,
      contentTextStyle: const TextStyle(
        fontFamily: 'Archivo',
        color: TgColors.foreground,
      ),
      behavior: SnackBarBehavior.floating,
      shape: controlShape,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: TgColors.primary,
      linearTrackColor: TgColors.raised,
      circularTrackColor: TgColors.raised,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: TgColors.primary,
      foregroundColor: TgColors.primaryForeground,
      elevation: 2,
      shape: rounded,
    ),
  );
}
