import 'package:flutter/material.dart';

/// Central color palette for the Laundry Service Management System.
///
/// The visual identity is a light, premium rose theme: soft pink canvas,
/// clean white cards, magenta as the primary action color, and deep plum
/// text for strong readable contrast. Rose gold is used sparingly for
/// premium highlights such as verification marks and ratings.
class AppColors {
  AppColors._();

  // ---- Brand ----
  /// Main action color used on primary buttons, headers and selected states.
  static const Color primaryPink = Color(0xFFD81B76);

  /// Deeper magenta for gradient ends and pressed states.
  static const Color deepPink = Color(0xFFB0145E);

  /// Mid tone used for secondary emphasis and icon strokes.
  static const Color rose = Color(0xFFE85AA0);

  /// Tint used behind icons, chips and soft badges.
  static const Color softPink = Color(0xFFFBD5E7);

  /// Very light wash used for section tints inside white cards.
  static const Color paleBlush = Color(0xFFFDEAF3);

  static const Color pinkGlow = Color(0x33D81B76);

  /// Rose gold, reserved for premium highlights such as verified marks,
  /// star ratings and earnings figures.
  static const Color accent = Color(0xFFC9915F);

  // ---- Surfaces ----
  /// The page canvas. Every scaffold sits on this soft pink.
  static const Color background = Color(0xFFFDF0F6);

  /// Cards, sheets and dialogs.
  static const Color surface = Color(0xFFFFFFFF);

  /// Input fields and subtle inner panels inside a white card.
  static const Color surfaceAlt = Color(0xFFFDF2F8);

  /// Bottom navigation and other slightly stronger pink panels.
  static const Color surfaceMuted = Color(0xFFFBE4F0);

  static const Color white = Color(0xFFFFFFFF);

  // ---- Text ----
  /// Headings and primary copy. A deep plum rather than pure black, which
  /// keeps the theme warm while staying well above contrast minimums.
  static const Color textPrimary = Color(0xFF3D0A28);

  /// Body copy on light surfaces.
  static const Color textBody = Color(0xFF6B4357);

  /// Secondary and helper copy.
  static const Color textMuted = Color(0xFF9B7C8C);

  /// Hairline borders around cards and inputs.
  static const Color border = Color(0xFFF3CFE2);

  // ---- Status ----
  static const Color success = Color(0xFF1FA463);
  static const Color warning = Color(0xFFD98324);
  static const Color error = Color(0xFFD62F4B);
  static const Color info = Color(0xFF3B84C9);

  // ---- Provider type badges ----
  static const Color formalBadge = Color(0xFF3B84C9);
  static const Color mamaFuaBadge = Color(0xFFC9915F);

  /// Used on headers, primary buttons and hero panels.
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE23C86), primaryPink],
  );

  /// The page background wash, slightly lighter at the top.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFEF5F9), background],
  );
}
