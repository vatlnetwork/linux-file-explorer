import 'package:flutter/material.dart';

class MacOSTheme {
  static ThemeData getTheme({
    required Brightness brightness,
    required FontStyle fontStyle,
  }) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black87;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme:
          isDark
              ? ColorScheme.dark(
                primary: const Color(0xFF0A84FF),
                secondary: const Color(0xFF5E5CE6),
                surface: const Color(0xFF1E1E1E),
                error: const Color(0xFFFF453A),
              )
              : ColorScheme.light(
                primary: const Color(0xFF007AFF),
                secondary: const Color(0xFF5856D6),
                surface: Colors.white,
                error: const Color(0xFFFF3B30),
              ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontStyle: fontStyle,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontStyle: fontStyle,
        ),
        bodyLarge: TextStyle(
          fontSize: 13,
          color: textColor,
          fontStyle: fontStyle,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          color: textColorSecondary,
          fontStyle: fontStyle,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        shadowColor: Colors.black.withValues(alpha: 13),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF007AFF),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF007AFF),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: Colors.grey.shade200,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        titleTextStyle: const TextStyle(fontSize: 13, color: Colors.black),
        subtitleTextStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0xFF007AFF).withValues(alpha: 51),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF007AFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF007AFF)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            return const Color(0xFF34C759).withValues(alpha: 77);
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
      iconTheme: IconThemeData(
        size: 20,
        weight: 400,
        color: isDark ? Colors.white : Colors.black87,
        grade: 0,
      ),
    );
  }

  static ThemeData get lightTheme =>
      getTheme(brightness: Brightness.light, fontStyle: FontStyle.normal);

  static ThemeData get darkTheme =>
      getTheme(brightness: Brightness.dark, fontStyle: FontStyle.normal);
}
