import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreset { custom }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _useAnimationsKey = 'use_animations';

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blueAccent;
  bool _useAnimations = true;

  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get useAnimations => _useAnimations;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeString = _prefs.getString(_themeKey) ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );

    // Load accent color
    final accentColorValue =
        _prefs.getInt(_accentColorKey) ??
        const Color(0xFF2196F3).toARGB32(); // Material Blue 500
    _accentColor = Color(accentColorValue);

    // Load animation preference
    _useAnimations = _prefs.getBool(_useAnimationsKey) ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_themeKey, mode.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;
    _accentColor = color;
    await _prefs.setInt(_accentColorKey, color.toARGB32());
    notifyListeners();
  }

  Future<void> setUseAnimations(bool useAnimations) async {
    if (_useAnimations == useAnimations) return;
    _useAnimations = useAnimations;
    await _prefs.setBool(_useAnimationsKey, useAnimations);
    notifyListeners();
  }

  void toggleTheme() {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _accentColor,
        primaryContainer: _accentColor.withValues(alpha: 0.1),
        secondary: _accentColor,
        secondaryContainer: _accentColor.withValues(alpha: 0.05),
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF5F5F5),
        error: const Color(0xFFE53935),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.all(12),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87, size: 24),
      tabBarTheme: TabBarThemeData(
        labelColor: _accentColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: _accentColor),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        disabledColor: Colors.grey.shade200,
        selectedColor: _accentColor.withValues(alpha: 0.2),
        secondarySelectedColor: _accentColor.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: _accentColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      pageTransitionsTheme:
          _useAnimations
              ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                },
              )
              : const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
                },
              ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: _accentColor,
        primaryContainer: _accentColor.withValues(alpha: 0.2),
        secondary: _accentColor,
        secondaryContainer: _accentColor.withValues(alpha: 0.1),
        surface: const Color(0xFF1E1E1E),
        surfaceContainerHighest: const Color(0xFF121212),
        error: const Color(0xFFCF6679),
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onSurface: Colors.white,
        onError: Colors.black87,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800),
        ),
        margin: const EdgeInsets.all(12),
        color: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      tabBarTheme: TabBarThemeData(
        labelColor: _accentColor,
        unselectedLabelColor: Colors.grey.shade400,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: _accentColor),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        disabledColor: Colors.grey.shade800,
        selectedColor: _accentColor.withValues(alpha: 0.2),
        secondarySelectedColor: _accentColor.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(16),
        ),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: _accentColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      pageTransitionsTheme:
          _useAnimations
              ? const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.linux: ZoomPageTransitionsBuilder(),
                  TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: ZoomPageTransitionsBuilder(),
                },
              )
              : const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
                  TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
                },
              ),
    );
  }
}

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
