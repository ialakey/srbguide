import 'package:flutter/material.dart';

/// Material 3 theming for the app.
///
/// Both themes come from one seed so light and dark stay in step, and component
/// styles live here rather than being re-specified with hardcoded
/// `TextStyle(fontSize: 18, fontWeight: bold)` on every screen.
///
/// The surface family is deliberately **neutral** rather than seed-tinted.
/// `ColorScheme.fromSeed` tints every surface with the seed hue, which turns
/// the whole app into a wash of one colour. Colour is reserved for things that
/// mean something — actions, the active tab, an urgent deadline — while
/// backgrounds and cards stay grey.
class AppTheme {
  AppTheme._();

  /// Accent blue. Used for actions and emphasis, never for page backgrounds.
  static const Color seed = Color(0xFF1B5FA8);

  /// Amber for "running out" states.
  ///
  /// Material 3 has no warning role, and `tertiary` derived from a blue seed
  /// comes out mauve — decorative rather than urgent — so this is set by hand.
  /// Both tones clear 4.5:1 against their own background.
  static const Color _warningLight = Color(0xFFA35A00);
  static const Color _warningDark = Color(0xFFFFB95C);

  static Color warningOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? _warningDark
          : _warningLight;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  // --- Neutral surface ramps -----------------------------------------------

  static const Color _lightSurface = Color(0xFFFAFAFA);
  static const Color _lightLowest = Color(0xFFFFFFFF);
  static const Color _lightLow = Color(0xFFF6F6F8);
  static const Color _lightContainer = Color(0xFFF1F1F4);
  static const Color _lightHigh = Color(0xFFEBEBEF);
  static const Color _lightHighest = Color(0xFFE4E5EA);
  static const Color _lightOn = Color(0xFF1A1C1E);
  static const Color _lightOnVariant = Color(0xFF5A6068);
  static const Color _lightOutline = Color(0xFF8C9198);
  static const Color _lightOutlineVariant = Color(0xFFDBDDE2);

  static const Color _darkSurface = Color(0xFF121316);
  static const Color _darkLowest = Color(0xFF0C0D0F);
  static const Color _darkLow = Color(0xFF17181B);
  static const Color _darkContainer = Color(0xFF1C1D21);
  static const Color _darkHigh = Color(0xFF232428);
  static const Color _darkHighest = Color(0xFF2A2C31);
  static const Color _darkOn = Color(0xFFE4E5E9);
  static const Color _darkOnVariant = Color(0xFFA7ADB6);
  static const Color _darkOutline = Color(0xFF71777F);
  static const Color _darkOutlineVariant = Color(0xFF33363C);

  static ColorScheme _scheme(Brightness brightness) {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final bool isDark = brightness == Brightness.dark;

    return base.copyWith(
      surface: isDark ? _darkSurface : _lightSurface,
      surfaceContainerLowest: isDark ? _darkLowest : _lightLowest,
      surfaceContainerLow: isDark ? _darkLow : _lightLow,
      surfaceContainer: isDark ? _darkContainer : _lightContainer,
      surfaceContainerHigh: isDark ? _darkHigh : _lightHigh,
      surfaceContainerHighest: isDark ? _darkHighest : _lightHighest,
      onSurface: isDark ? _darkOn : _lightOn,
      onSurfaceVariant: isDark ? _darkOnVariant : _lightOnVariant,
      outline: isDark ? _darkOutline : _lightOutline,
      outlineVariant: isDark ? _darkOutlineVariant : _lightOutlineVariant,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = _scheme(brightness);
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          // A hairline keeps cards legible now that they are not tinted.
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? _darkLow : _lightLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      // Both button themes ask for a full-width minimum. That reads well in a
      // column, but a Row gives its children an unbounded main-axis width, so
      // a button placed directly in a Row must be wrapped in Expanded or given
      // a width of its own — otherwise it demands infinite width and the whole
      // subtree fails to lay out.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll<BorderSide>(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _darkHigh : _lightHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: isDark ? _darkHigh : _lightHigh,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? _darkHigh : _lightLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? _darkLow : _lightLowest,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
    );
  }
}
