import 'package:flutter/material.dart';

class GoogleTheme {
  static ThemeData getTheme({
    required Brightness brightness,
    required FontStyle fontStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          isDark
              ? ColorScheme.dark(
                primary: const Color(0xFF8AB4F8), // Google Blue Light
                secondary: const Color(0xFF81C995), // Google Green Light
                surface: const Color(0xFF202124), // Google Dark Gray
                error: const Color(0xFFF28B82), // Google Red Light
              )
              : ColorScheme.light(
                primary: const Color(0xFF1A73E8), // Google Blue
                secondary: const Color(0xFF34A853), // Google Green
                surface: const Color(0xFFFFFFFF), // Pure white surface
                surfaceContainerHighest: const Color(0xFFEEF0F2),
                error: const Color(0xFFEA4335), // Google Red
                onSurface: Colors.black87,
                onSurfaceVariant: Colors.black54,
              ),
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF202124) : const Color(0xFFF8F9FA),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontStyle: fontStyle,
        ),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textColor,
          fontStyle: fontStyle,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
          fontStyle: fontStyle,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          color: textColor,
          fontStyle: fontStyle,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textColorSecondary,
          fontStyle: fontStyle,
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: const Color(0xFF1A73E8).withValues(alpha: 77),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1A73E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      iconTheme: IconThemeData(weight: 400, color: Colors.black87, grade: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A73E8)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF1A73E8).withValues(alpha: 128);
          }
          return Colors.grey.shade300;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.grey.shade200.withValues(alpha: 26);
          }
          return Colors.transparent;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  static ThemeData get lightTheme =>
      getTheme(brightness: Brightness.light, fontStyle: FontStyle.normal);

  static ThemeData get darkTheme =>
      getTheme(brightness: Brightness.dark, fontStyle: FontStyle.normal);
}
