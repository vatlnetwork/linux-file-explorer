import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiskUsageWidgetService extends ChangeNotifier {
  static const String _showDiskUsageKey = 'show_disk_usage_widget';

  bool _showDiskUsageWidget = true;

  bool get showDiskUsageWidget => _showDiskUsageWidget;

  DiskUsageWidgetService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showDiskUsageWidget = prefs.getBool(_showDiskUsageKey) ?? true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDiskUsageKey, _showDiskUsageWidget);
  }

  void toggleDiskUsageWidget() {
    _showDiskUsageWidget = !_showDiskUsageWidget;
    notifyListeners();
    _saveSettings();
  }

  void setShowDiskUsageWidget(bool value) {
    if (_showDiskUsageWidget == value) return;
    _showDiskUsageWidget = value;
    notifyListeners();
    _saveSettings();
  }
}
