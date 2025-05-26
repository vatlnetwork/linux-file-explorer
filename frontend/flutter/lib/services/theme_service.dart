import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/google_theme.dart';
import '../theme/macos_theme.dart';

enum ThemePreset { custom, google, macos }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _themePresetKey = 'theme_preset';
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';
  static const String _iconWeightKey = 'icon_weight';
  static const String _interfaceDensityKey = 'interface_density';
  static const String _useAnimationsKey = 'use_animations';
  static const String _customColorsKey = 'custom_colors';

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = Colors.blue;
  ThemePreset _themePreset = ThemePreset.custom;
  String _fontFamily = 'Roboto';
  double _fontSize = 14.0;
  double _iconWeight = 400;
  double _interfaceDensity = 0.0;
  bool _useAnimations = true;
  Map<String, Color> _customColors = {
    'primary': Colors.blue,
    'secondary': Colors.green,
    'surface': Colors.grey.shade100,
    'error': Colors.red,
  };

  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  ThemePreset get themePreset => _themePreset;
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get iconWeight => _iconWeight;
  double get interfaceDensity => _interfaceDensity;
  bool get useAnimations => _useAnimations;
  Map<String, Color> get customColors => _customColors;

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
        _prefs.getInt(_accentColorKey) ?? Colors.blue.toARGB32();
    _accentColor = Color(accentColorValue);

    // Load theme preset
    final presetString = _prefs.getString(_themePresetKey) ?? 'custom';
    _themePreset = ThemePreset.values.firstWhere(
      (preset) => preset.toString() == 'ThemePreset.$presetString',
      orElse: () => ThemePreset.custom,
    );

    // Load font settings
    _fontFamily = _prefs.getString(_fontFamilyKey) ?? 'Roboto';
    _fontSize = _prefs.getDouble(_fontSizeKey) ?? 14.0;

    // Load icon settings
    _iconWeight = _prefs.getDouble(_iconWeightKey) ?? 400;

    // Load interface density
    _interfaceDensity = _prefs.getDouble(_interfaceDensityKey) ?? 0.0;

    // Load animation preference
    _useAnimations = _prefs.getBool(_useAnimationsKey) ?? true;

    // Load custom colors
    final customColorsMap = _prefs.getString(_customColorsKey);
    if (customColorsMap != null) {
      final Map<String, dynamic> colorsJson = Map<String, dynamic>.from(
        jsonDecode(customColorsMap),
      );
      _customColors = colorsJson.map(
        (key, value) => MapEntry(key, Color(value as int)),
      );
    }

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

  Future<void> setThemePreset(ThemePreset preset) async {
    if (_themePreset == preset) return;
    _themePreset = preset;
    await _prefs.setString(_themePresetKey, preset.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setFontFamily(String fontFamily) async {
    if (_fontFamily == fontFamily) return;
    _fontFamily = fontFamily;
    await _prefs.setString(_fontFamilyKey, fontFamily);
    notifyListeners();
  }

  Future<void> setFontSize(double fontSize) async {
    if (_fontSize == fontSize) return;
    _fontSize = fontSize;
    await _prefs.setDouble(_fontSizeKey, fontSize);
    notifyListeners();
  }

  Future<void> setIconWeight(double weight) async {
    if (_iconWeight == weight) return;
    _iconWeight = weight;
    await _prefs.setDouble(_iconWeightKey, weight);
    notifyListeners();
  }

  Future<void> setInterfaceDensity(double density) async {
    if (_interfaceDensity == density) return;
    _interfaceDensity = density;
    await _prefs.setDouble(_interfaceDensityKey, density);
    notifyListeners();
  }

  Future<void> setUseAnimations(bool useAnimations) async {
    if (_useAnimations == useAnimations) return;
    _useAnimations = useAnimations;
    await _prefs.setBool(_useAnimationsKey, useAnimations);
    notifyListeners();
  }

  Future<void> setCustomColor(String key, Color color) async {
    if (_customColors[key] == color) return;
    _customColors[key] = color;
    await _prefs.setString(
      _customColorsKey,
      jsonEncode(
        _customColors.map((key, value) => MapEntry(key, value.toARGB32())),
      ),
    );
    notifyListeners();
  }

  void toggleTheme() {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    setThemeMode(newMode);
  }

  ThemeData getLightTheme() {
    switch (_themePreset) {
      case ThemePreset.google:
        return GoogleTheme.lightTheme;
      case ThemePreset.macos:
        return MacOSTheme.lightTheme;
      case ThemePreset.custom:
        return _getCustomTheme(Brightness.light);
    }
  }

  ThemeData getDarkTheme() {
    switch (_themePreset) {
      case ThemePreset.google:
        return GoogleTheme.darkTheme;
      case ThemePreset.macos:
        return MacOSTheme.darkTheme;
      case ThemePreset.custom:
        return _getCustomTheme(Brightness.dark);
    }
  }

  ThemeData _getCustomTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: _accentColor,
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: _fontSize),
        bodyMedium: TextStyle(fontSize: _fontSize * 0.9),
        bodySmall: TextStyle(fontSize: _fontSize * 0.8),
        titleLarge: TextStyle(fontSize: _fontSize * 1.5),
        titleMedium: TextStyle(fontSize: _fontSize * 1.2),
        titleSmall: TextStyle(fontSize: _fontSize),
      ),
      iconTheme: IconThemeData(
        size: 24,
        weight: _iconWeight,
        color: isDark ? Colors.white : Colors.black87,
      ),
      visualDensity: VisualDensity(
        horizontal: _interfaceDensity,
        vertical: _interfaceDensity,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform:
                _useAnimations
                    ? const CupertinoPageTransitionsBuilder()
                    : const NoAnimationPageTransitionsBuilder(),
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
