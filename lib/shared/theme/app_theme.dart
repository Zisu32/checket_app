import 'package:flutter/material.dart';

class AppTheme {
  // Main colors
  static const Color header = Color(0xFF11171C);
  static const Color background = Color(0xFF232F39);
  static const Color surface = Color(0xFF3B5061);
  
  // Status colors
  static const Color unpaid = Color(0xFFB71C1C);
  static const Color temporary = Color(0xFFE67B00);
  static const Color secret = Color(0xffffd500);
  static const Color active = Color(0xFF00B58B);
  static const Color forgotten = Color(0xFF0081C3);
  static const Color free = Color(0xFF818181);

  // Others
  static const Color white = Color(0xffdfdfdf);
  static const Color shadow = Color(0xff000000);

  // Font Sizes
  static const double xsmall = 12.0;
  static const double small = 16.0;
  static const double medium = 25.0;
  static const double large = 32.0;

  // Text-Inputfield
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    labelStyle: const TextStyle(color: free),
    floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
      return const TextStyle(color: free);
    }),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: surface),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: surface),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: active),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: unpaid),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: unpaid),
    ),
  );
}
