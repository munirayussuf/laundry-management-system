import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system. Headings use Poppins for the rounded, friendly weight
/// seen across the product screens, and body copy uses Inter for clean
/// readability at small sizes.
///
/// Every style defaults to deep plum text, which is correct on the light
/// rose canvas and on white cards. Pass AppColors.white explicitly for text
/// that sits on a pink header or a filled pink button.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle heading2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle heading3({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyMedium({Color color = AppColors.textBody}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: color);

  static TextStyle buttonLabel({Color color = AppColors.white}) =>
      GoogleFonts.poppins(fontSize: 15.5, fontWeight: FontWeight.w600, color: color);

  static TextStyle caption({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: color);
}
