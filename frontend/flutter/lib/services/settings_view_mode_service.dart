import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SettingsViewMode { comfortable, compact }

class SettingsViewModeService extends ChangeNotifier {
  static const String _viewModeKey = 'settings_view_mode';

  late SharedPreferences _prefs;
  SettingsViewMode _viewMode = SettingsViewMode.comfortable;

  SettingsViewMode get viewMode => _viewMode;

  SettingsViewModeService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final viewModeString = _prefs.getString(_viewModeKey) ?? 'comfortable';
    _viewMode = SettingsViewMode.values.firstWhere(
      (mode) => mode.toString() == 'SettingsViewMode.$viewModeString',
      orElse: () => SettingsViewMode.comfortable,
    );

    notifyListeners();
  }

  Future<void> setViewMode(SettingsViewMode mode) async {
    if (_viewMode == mode) return;
    _viewMode = mode;
    await _prefs.setString(_viewModeKey, mode.toString().split('.').last);
    notifyListeners();
  }

  // Get the content padding based on view mode
  EdgeInsets getContentPadding() {
    switch (_viewMode) {
      case SettingsViewMode.comfortable:
        return const EdgeInsets.all(24.0);
      case SettingsViewMode.compact:
        return const EdgeInsets.all(16.0);
    }
  }

  // Get the spacing between sections based on view mode
  double getSectionSpacing() {
    switch (_viewMode) {
      case SettingsViewMode.comfortable:
        return 24.0;
      case SettingsViewMode.compact:
        return 16.0;
    }
  }

  // Get the icon size based on view mode
  double getIconSize() {
    switch (_viewMode) {
      case SettingsViewMode.comfortable:
        return 24.0;
      case SettingsViewMode.compact:
        return 20.0;
    }
  }

  // Get the title font size based on view mode
  double getTitleFontSize() {
    switch (_viewMode) {
      case SettingsViewMode.comfortable:
        return 24.0;
      case SettingsViewMode.compact:
        return 20.0;
    }
  }
}
