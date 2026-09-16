import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // 1. 🌟 Primary Brand & Gold Colors
  // ==========================================
  /// Primary buttons, active highlights, price highlights
  static const Color primary = Color(0xFFC59B27); // Antique Culinary Gold
  static const Color primaryGold = Color(0xFFC59B27);

  /// Gradient highlights, borders, emblems, ratings
  static const Color gold = Color(0xFFD4AF37); // Imperial Gold
  static const Color goldAccent = Color(0xFFD4AF37);

  /// Header subtext, active text, badge borders
  static const Color goldLight = Color(0xFFFFDF7D); // Pale Sunlight Gold

  /// Gradient depth, shadows, emblem rims
  static const Color primaryDark = Color(0xFF8C581E); // Warm Deep Bronze
  static const Color bronze = Color(0xFF8C581E);

  /// Category chip backgrounds, subtle card fills
  static const Color primaryLight = Color(0xFFFFF7E6); // Warm Ivory Linen Tint
  static const Color linenTint = Color(0xFFFFF7E6);

  // ==========================================
  // 2. ☕ Deep Espresso & Dark Accents
  // ==========================================
  /// Top AppBar gradients, Splash screen background
  static const Color espressoDeep = Color(0xFF261208); // Dark Roast Espresso

  /// Gradient midpoint for headers & banners
  static const Color espressoMid = Color(0xFF3F1D0D); // Roasted Mocha Bronze

  /// Bottom gradient endpoint, bottom bar contrast
  static const Color espressoDark = Color(0xFF1C0C05); // Pitch Roast Charcoal

  /// Dark mode surfaces & elevated containers
  static const Color darkSurface = Color(0xFF2A150A); // Deep Roast Surface

  // ==========================================
  // 3. 📄 Backgrounds & Neutrals
  // ==========================================
  /// Main screen body background
  static const Color appBackground = Color(0xFFF4F6F9); // Cool Slate White
  static const Color bgDark = Color(0xFFF4F6F9);

  /// Modal & sheet backgrounds
  static const Color linenNeutral = Color(0xFFFBF8F3); // Soft Warm Linen Paper

  /// Food item cards, bottom sheet sheets
  static const Color cardSurface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Quantity stepper background, inactive chips, input backgrounds
  static const Color stepperNeutral = Color(0xFFF1F5F9); // Off-White Slate
  static const Color bgSlate = Color(0xFFF1F5F9);
  static const Color surfaceSlate = Color(0xFFF1F5F9);

  /// Category chips & card divider lines
  static const Color borderNeutral = Color(0xFFE5DDD0); // Warm Sand Gray
  static const Color borderSlate = Color(0xFFE5DDD0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  /// Highlight surface (tinted Ivory Linen)
  static const Color surfaceHighlight = Color(0xFFFFF7E6);

  // ==========================================
  // 4. ✍️ Typography Colors
  // ==========================================
  /// Dish names, section headings, bill titles
  static const Color titleHeading = Color(0xFF2A1508); // Deep Espresso Charcoal
  static const Color textPrimary = Color(0xFF2A1508);

  /// Descriptions, timestamps, instructions
  static const Color bodySecondary = Color(0xFF6E5F55); // Muted Slate Gray
  static const Color textSecondary = Color(0xFF6E5F55);

  /// Search input placeholder, disabled text
  static const Color hintPlaceholder = Color(0xFF9E9E9E); // Soft Light Gray
  static const Color textMuted = Color(0xFF9E9E9E);

  /// App bar title text (SPICE HAVEN)
  static const Color lightOnDarkTitle = Color(0xFFFFF7ED); // Ivory Cream

  /// Tagline text (GOOD FOOD BRIGHTER DAYS)
  static const Color lightOnDarkSub = Color(0xFFFFD199); // Soft Warm Gold

  // ==========================================
  // 5. 🚦 Status & Culinary Badges
  // ==========================================
  /// Vegetarian food indicator badge
  static const Color vegMark = Color(0xFF2E7D32); // Forest Leaf Green

  /// Non-vegetarian food indicator badge
  static const Color nonVegMark = Color(0xFFC62828); // Crimson Red

  /// Order confirmed status, delivered badges, success
  static const Color statusSuccess = Color(0xFF2ECC71); // Mint Emerald

  /// Cooking / preparing in progress status, warning
  static const Color statusWarning = Color(0xFFF39C12); // Amber Orange

  /// Dish star ratings
  static const Color ratingStar = Color(0xFFFFC107); // Warm Amber

  /// Clear cart action, error alerts
  static const Color statusError = Color(0xFFD32F2F); // Crimson Red Accent

  // ==========================================
  // 6. ✨ Signature Gradients
  // ==========================================
  /// Luxury Header Gradient: [#261208, #3F1D0D, #1C0C05]
  static const LinearGradient luxuryHeaderGradient = LinearGradient(
    colors: [
      Color(0xFF261208), // Dark Roast Espresso
      Color(0xFF3F1D0D), // Roasted Mocha Bronze
      Color(0xFF1C0C05), // Pitch Roast Charcoal
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Imperial Action Button Gradient: [#D4AF37, #A07212]
  static const LinearGradient imperialActionGradient = LinearGradient(
    colors: [
      Color(0xFFD4AF37), // Imperial Gold
      Color(0xFFA07212), // Deep Antique Gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gold Ring Emblem Gradient: [#FFDF7D, #D4AF37, #8C581E]
  static const LinearGradient goldRingGradient = LinearGradient(
    colors: [
      Color(0xFFFFDF7D), // Pale Sunlight Gold
      Color(0xFFD4AF37), // Imperial Gold
      Color(0xFF8C581E), // Warm Deep Bronze
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // Backward-Compatible Aliases for Legacy Code
  // ==========================================
  static const Color orange = primaryGold;
  static const Color orangeNeon = goldAccent;
  static const Color orangeDark = primaryDark;
  static const Color orangeLight = primaryLight;
  static const Color orangeBorder = borderNeutral;
  static const Color orangeGlow = Color(0x33C59B27);

  static const Color emerald = primaryGold;
  static const Color emeraldNeon = goldAccent;
  static const Color emeraldGlow = Color(0x33C59B27);

  static const Color amber = statusWarning;
  static const Color amberGlow = Color(0x33F39C12);
  static const Color amberLight = primaryLight;

  static const Color rose = statusError;
  static const Color roseGlow = Color(0x33D32F2F);
  static const Color roseLight = Color(0xFFFDF2F2);

  // ==========================================
  // Global ThemeData
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: appBackground,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: goldAccent,
        error: statusError,
        surface: cardSurface,
        onPrimary: Colors.white,
        onSecondary: espressoDeep,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: espressoDeep,
        foregroundColor: lightOnDarkTitle,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightOnDarkTitle),
        titleTextStyle: TextStyle(
          color: lightOnDarkTitle,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNeutral, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: stepperNeutral,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: bodySecondary, fontSize: 14),
        hintStyle: const TextStyle(color: hintPlaceholder, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNeutral),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNeutral),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGold, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusError, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x40C59B27),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: primaryLight,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryGold);
          }
          return const IconThemeData(color: bodySecondary);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(
                color: primaryGold, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: bodySecondary, fontSize: 12);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: espressoDeep,
        contentTextStyle: const TextStyle(color: lightOnDarkTitle),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
