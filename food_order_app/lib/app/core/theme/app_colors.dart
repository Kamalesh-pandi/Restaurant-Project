import 'package:flutter/material.dart';

class AppColors {
  // Brand Warm Antique Gold & Espresso System (Spice Haven Identity)
  static const Color primary = Color(0xFFC59B27); // Rich Antique Culinary Gold
  static const Color primaryDark = Color(0xFF8C581E); // Warm Deep Bronze
  static const Color primaryLight = Color(0xFFFFF7E6); // Warm Ivory Linen Tint
  static const Color accent = Color(0xFFD4AF37); // Imperial Gold Accent
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFDF7D);

  // Deep Espresso & Gold Gradient Pairs for Headers & Hero Containers
  static const Color gradientStart = Color(0xFF261208); // Dark Roast Espresso
  static const Color gradientEnd = Color(0xFF3F1D0D); // Warm Roasted Bronze

  // Action / Button Gradient
  static const List<Color> buttonGradient = [
    Color(0xFFD4AF37),
    Color(0xFFA07212),
  ];

  // Surface & Neutral Colors (Clean Warm Linen & Deep Espresso)
  static const Color backgroundLight = Color(0xFFFBF8F3); // Soft Warm Linen Paper
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color backgroundDark = Color(0xFF1A0C06); // Deep Roast Charcoal
  static const Color surfaceDark = Color(0xFF2A150A);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF221107); // Deep Roast Espresso
  static const Color textSecondaryLight = Color(0xFF6E5F55); // Muted Warm Earth
  static const Color textPrimaryDark = Color(0xFFFFF6EE);
  static const Color textSecondaryDark = Color(0xFFFFE0C8);

  // Status & Feedback Colors
  static const Color success = Color(0xFF2ECC71); // Soft Mint
  static const Color error = Color(0xFFD32F2F); // Crimson Red
  static const Color warning = Color(0xFFF39C12); // Amber Warning
  static const Color info = Color(0xFFC59B27); // Gold Info

  // Veg / Non-Veg Indicator Colors
  static const Color vegGreen = Color(0xFF2E7D32);
  static const Color nonVegRed = Color(0xFFC62828);

  // Glassmorphism & Shimmer
  static final Color glassBorder = Colors.white.withOpacity(0.3);
  static final Color glassBackground = Colors.white.withOpacity(0.2);
  static const Color shimmerBase = Color(0xFFF4EDE2);
  static const Color shimmerHighlight = Color(0xFFFCF8F2);
  static const Color shimmerBaseDark = Color(0xFF3A1C0B);
  static const Color shimmerHighlightDark = Color(0xFF522810);
}
