import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Single source of truth for the application ThemeData.
///
/// The app runs one light rose theme: a soft pink canvas, white cards with
/// hairline pink borders, generously rounded corners and magenta as the
/// action color.
class AppTheme {
  AppTheme._();

  /// Corner radius used consistently across cards, inputs and sheets.
  static const double radius = 18;

  /// Pill radius for primary buttons and chips.
  static const double pillRadius = 30;

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryPink,
        secondary: AppColors.rose,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryPink),
        titleTextStyle: AppTextStyles.heading3(),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.pinkGlow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          textStyle: AppTextStyles.buttonLabel(),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          backgroundColor: AppColors.surface,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: AppColors.primaryPink, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          textStyle: AppTextStyles.buttonLabel(color: AppColors.primaryPink),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryPink,
          textStyle: AppTextStyles.buttonLabel(color: AppColors.primaryPink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
        labelStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
        floatingLabelStyle: AppTextStyles.bodyMedium(color: AppColors.primaryPink),
        prefixIconColor: AppColors.rose,
        suffixIconColor: AppColors.rose,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedItemColor: AppColors.primaryPink,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.caption(color: AppColors.primaryPink),
        unselectedLabelStyle: AppTextStyles.caption(),
        showUnselectedLabels: true,
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryPink,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppTextStyles.bodySmall(color: AppColors.textBody),
        secondaryLabelStyle: AppTextStyles.bodySmall(color: AppColors.white),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.white : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryPink
              : AppColors.border,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 4)),
        titleTextStyle: AppTextStyles.heading3(),
        contentTextStyle: AppTextStyles.bodyMedium(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextStyles.bodyMedium(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primaryPink,
        textColor: AppColors.textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryPink),
      dividerColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.primaryPink),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
