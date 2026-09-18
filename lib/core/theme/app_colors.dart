import 'package:flutter/material.dart';

/// Edible fresh travel visual system.
/// Strong aqua background, colored surfaces and high-contrast organic accents.
abstract final class AppColors {
  static const Color background = Color(0xFF2D2D2D);
  static const Color backgroundDeep = Color(0xFF242424);
  static const Color surface = Color(0xFFFFE2C4);
  static const Color surfaceStrong = Color(0xFFFFE2C4);
  static const Color surfaceDeep = Color(0xFFFFE2C4);
  static const Color surfaceMint = Color(0xFFFFE2C4);

  static const Color primary = Color(0xFF007F78);
  static const Color primaryDark = Color(0xFF075B57);
  static const Color primarySoft = Color(0xFF8DE0D7);

  static const Color textPrimary = Color(0xFF073B39);
  static const Color textMuted = Color(0xFF356865);
  static const Color textLight = Color(0xFF6D9894);
  static const Color border = Color(0xFF70C9C0);
  static const Color divider = Color(0xFF92D9D2);

  static const Color orange = Color(0xFFF28C38);
  static const Color orangeSoft = Color(0xFFFFDDBF);
  static const Color freshGreen = Color(0xFF39C77A);
  static const Color greenSoft = Color(0xFFC8F1D9);
  static const Color darkNavy = Color(0xFF073B39);
  static const Color darkCharcoal = Color(0xFF0B4B47);

  static const Color success = Color(0xFF167B5C);
  static const Color warning = Color(0xFFD98A16);
  static const Color error = Color(0xFFC94E4E);
  static const Color info = Color(0xFF277EB0);

  static const Color turquoise = primary;
  static const Color turquoiseDark = primaryDark;
  static const Color turquoiseLight = Color(0xFF72D9D0);
  static const Color tealAccent = primary;
  static const Color orangeDark = Color(0xFFD97623);
  static const Color orangeLight = Color(0xFFFFD2AA);
  static const Color peachy = orange;
  static const Color greenDark = Color(0xFF167B5C);
  static const Color greenLight = Color(0xFF70DCA4);
  static const Color emerald = Color(0xFF126A53);
  static const Color lightGray = Color(0xFFDDF3EF);
  static const Color mediumGray = border;
  static const Color gray = Color(0xFFA7C4C0);
  static const Color darkGray = Color(0xFF476A67);
  static const Color textBrightBlack = Color(0xFF111111);
  static const Color textSoftWhite = Color(0xFFE6E6E6);
  static const Color textDark = textPrimary;
  static const Color backgroundWhite = surfaceMint;
  static const Color backgroundLight = surface;
  static const Color backgroundGray = Color(0xFF9BDCD5);
  static const Color darkBackground = darkNavy;

  static const LinearGradient gradientBrand = LinearGradient(
    colors: [Color(0xFF007F78), Color(0xFF35C77A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientTurquoiseToGreen = LinearGradient(
    colors: [Color(0xFF007F78), Color(0xFF35C77A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientOrangeToTurquoise = LinearGradient(
    colors: [orange, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientGreenToOrange = LinearGradient(
    colors: [freshGreen, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientPremium = LinearGradient(
    colors: [primary, orange, freshGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
