import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Primary: electric purple ───────────────────────────────────────────────
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF5B21B6);

  // ── Accent: hot pink ───────────────────────────────────────────────────────
  static const accent = Color(0xFFEC4899);
  static const accentLight = Color(0xFFF9A8D4);

  // ── Light mode surfaces (lavender-tinted) ──────────────────────────────────
  static const background = Color(0xFFF3F0FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEDE9FE);
  static const textPrimary = Color(0xFF1E1B4B);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const border = Color(0xFFDDD6FE);
  static const borderFocus = Color(0xFF7C3AED);

  // ── Dark mode surfaces (deep indigo/black) ─────────────────────────────────
  static const darkBackground = Color(0xFF0F0A1E);
  static const darkSurface = Color(0xFF1A1035);
  static const darkSurfaceVariant = Color(0xFF221440);
  static const darkText = Color(0xFFEDE9FE);
  static const darkTextSecondary = Color(0xFF9891BF);
  static const darkTextTertiary = Color(0xFF4A4170);
  static const darkBorder = Color(0xFF2D1F5E);

  // ── Semantics ──────────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
}

/// Named gradients used throughout the app.
class AppGradients {
  AppGradients._();

  /// Electric purple → hot pink — primary CTA gradient
  static const primary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Violet-only gradient
  static const violet = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rose/pink gradient
  static const rose = LinearGradient(
    colors: [Color(0xFFBE185D), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cyan gradient
  static const cyan = LinearGradient(
    colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Emerald gradient
  static const emerald = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Amber gradient
  static const amber = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep card background (dark mode only)
  static const card = LinearGradient(
    colors: [Color(0xFF2D1F5E), Color(0xFF1A1035)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme-aware color getters. Always use these instead of raw AppColors
/// constants for surfaces, borders, and text that adapt to dark mode.
extension AppColorsX on BuildContext {
  bool get _dk => Theme.of(this).brightness == Brightness.dark;

  Color get cSurface => _dk ? AppColors.darkSurface : AppColors.surface;
  Color get cSurfaceVariant =>
      _dk ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
  Color get cBorder => _dk ? AppColors.darkBorder : AppColors.border;
  Color get cBackground =>
      _dk ? AppColors.darkBackground : AppColors.background;
  Color get cTextPrimary =>
      _dk ? AppColors.darkText : AppColors.textPrimary;
  Color get cTextSecondary =>
      _dk ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get cTextTertiary =>
      _dk ? AppColors.darkTextTertiary : AppColors.textTertiary;

  // Glass helpers
  Color get cGlass => _dk
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.85);
  Color get cGlassBorder => _dk
      ? Colors.white.withValues(alpha: 0.10)
      : AppColors.border.withValues(alpha: 0.7);
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(base.textTheme, Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      dividerTheme:
          const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle:
            GoogleFonts.ubuntu(fontSize: 12, color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(base.textTheme, Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.ubuntu(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      inputDecorationTheme: _buildInputTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle:
            GoogleFonts.ubuntu(fontSize: 12, color: AppColors.darkText),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = isDark ? AppColors.darkText : AppColors.textPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return GoogleFonts.ubuntuTextTheme(base).copyWith(
      displayLarge:
          GoogleFonts.ubuntu(fontSize: 36, fontWeight: FontWeight.w800, color: text),
      displayMedium:
          GoogleFonts.ubuntu(fontSize: 30, fontWeight: FontWeight.w800, color: text),
      headlineLarge:
          GoogleFonts.ubuntu(fontSize: 24, fontWeight: FontWeight.w700, color: text),
      headlineMedium:
          GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.w700, color: text),
      headlineSmall:
          GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w700, color: text),
      titleLarge:
          GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w600, color: text),
      titleMedium:
          GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w500, color: text),
      titleSmall:
          GoogleFonts.ubuntu(fontSize: 13, fontWeight: FontWeight.w600, color: text),
      bodyLarge:
          GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w400, color: text),
      bodyMedium:
          GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w400, color: text),
      bodySmall:
          GoogleFonts.ubuntu(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:
          GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w700, color: text),
    );
  }

  static InputDecorationTheme _buildInputTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.ubuntu(
        fontSize: 14,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.textSecondary,
      ),
      hintStyle: GoogleFonts.ubuntu(
        fontSize: 14,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );

  static TextButtonThemeData _buildTextButtonTheme() =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle:
              GoogleFonts.ubuntu(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
}
