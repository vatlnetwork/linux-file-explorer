import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  // Always use system theme
  final ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // For compatibility with existing code
  bool get isDarkMode => false;
  bool get isLightMode => false;
  bool get isSystemMode => true;

  ThemeService() {
    // No need to load theme mode as we always use system
  }

  // For compatibility with existing code, but does nothing
  Future<void> setThemeMode(ThemeMode mode) async {
    // Do nothing - we always use system theme
    return;
  }

  // For compatibility with existing code, but does nothing
  void toggleTheme() {
    // Do nothing - we always use system theme
    return;
  }
}
