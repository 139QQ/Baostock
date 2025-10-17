import 'package:flutter/material.dart';

class AppTheme {
  static Color primaryColor = const Color(0xFF2563EB);
  static Color successColor = const Color(0xFF16A34A);
  static Color warningColor = const Color(0xFFCA8A04);
  static Color errorColor = const Color(0xFFDC2626);
  static Color neutralColor = const Color(0xFF6B7280);
  static Color backgroundColor = const Color(0xFFF9FAFB);
  static Color cardColor = const Color(0xFFFFFFFF);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    fontFamily: 'Microsoft YaHei',
  );

  static TextStyle headlineLarge = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF000000),
  );

  static TextStyle headlineMedium = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF000000),
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    color: Color(0xDD000000),
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    color: Color(0x8A000000),
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    color: Color(0x73000000),
  );
}
