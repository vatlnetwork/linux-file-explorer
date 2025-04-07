import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusBarService extends ChangeNotifier {
  static const String _showStatusBarKey = 'show_status_bar';
  static const String _showIconControlsKey = 'show_icon_controls';
  
  bool _showStatusBar = true;
  bool _showIconControls = true;
  
  bool get showStatusBar => _showStatusBar;
  bool get showIconControls => _showIconControls;
  
  StatusBarService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _showStatusBar = prefs.getBool(_showStatusBarKey) ?? true;
    _showIconControls = prefs.getBool(_showIconControlsKey) ?? true;
    
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_showStatusBarKey, _showStatusBar);
    await prefs.setBool(_showIconControlsKey, _showIconControls);
  }
  
  void toggleStatusBar() {
    _showStatusBar = !_showStatusBar;
    notifyListeners();
    _saveSettings();
  }
  
  void toggleIconControls() {
    _showIconControls = !_showIconControls;
    notifyListeners();
    _saveSettings();
  }
  
  void setShowStatusBar(bool value) {
    if (_showStatusBar == value) return;
    _showStatusBar = value;
    notifyListeners();
    _saveSettings();
  }
  
  void setShowIconControls(bool value) {
    if (_showIconControls == value) return;
    _showIconControls = value;
    notifyListeners();
    _saveSettings();
  }
} 