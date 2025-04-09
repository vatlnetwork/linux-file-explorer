import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IconSizeService extends ChangeNotifier {
  static const String _iconSizeKey = 'icon_size';
  static const String _uiScaleKey = 'ui_scale';
  
  // Default sizes for list and grid views
  static const double _defaultListIconSize = 24.0;
  static const double _defaultGridIconSize = 48.0;
  
  // Default UI scale factors
  static const double _defaultListUIScale = 1.0;
  static const double _defaultGridUIScale = 1.0;
  
  // Size constraints
  static const double _minListIconSize = 16.0;
  static const double _maxListIconSize = 48.0;
  static const double _minGridIconSize = 24.0;
  static const double _maxGridIconSize = 96.0;
  
  // UI scale constraints
  static const double _minListUIScale = 0.7;
  static const double _maxListUIScale = 1.5;
  static const double _minGridUIScale = 0.7;
  static const double _maxGridUIScale = 1.4;
  
  // Step sizes for resizing
  static const double _listResizeStep = 4.0;
  static const double _gridResizeStep = 8.0;
  
  // Step sizes for UI scaling
  static const double _listUIScaleStep = 0.1;
  static const double _gridUIScaleStep = 0.1;
  
  double _listIconSize = _defaultListIconSize;
  double _gridIconSize = _defaultGridIconSize;
  double _listUIScale = _defaultListUIScale;
  double _gridUIScale = _defaultGridUIScale;
  
  double get listIconSize => _listIconSize.clamp(_minListIconSize, _maxListIconSize);
  double get gridIconSize => _gridIconSize.clamp(_minGridIconSize, _maxGridIconSize);
  double get listUIScale => _listUIScale.clamp(_minListUIScale, _maxListUIScale);
  double get gridUIScale => _gridUIScale.clamp(_minGridUIScale, _maxGridUIScale);
  
  // List text sizes based on UI scale
  double get listTitleSize => 14.0 * _listUIScale;
  double get listSubtitleSize => 11.0 * _listUIScale;
  
  // Grid text sizes based on UI scale
  double get gridTitleSize => 14.0 * _gridUIScale;
  double get gridSubtitleSize => 11.0 * _gridUIScale;
  
  // Get list item height based on UI scale
  double get listItemHeight => 56.0 * _listUIScale;
  
  // Get grid item size (will affect the SliverGridDelegate)
  double get gridItemExtent => 120.0 * _gridUIScale;
  
  IconSizeService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _listIconSize = prefs.getDouble('${_iconSizeKey}_list') ?? _defaultListIconSize;
      _gridIconSize = prefs.getDouble('${_iconSizeKey}_grid') ?? _defaultGridIconSize;
      _listUIScale = prefs.getDouble('${_uiScaleKey}_list') ?? _defaultListUIScale;
      _gridUIScale = prefs.getDouble('${_uiScaleKey}_grid') ?? _defaultGridUIScale;
      
      // Apply safety constraints after loading
      _listIconSize = _listIconSize.clamp(_minListIconSize, _maxListIconSize);
      _gridIconSize = _gridIconSize.clamp(_minGridIconSize, _maxGridIconSize);
      _listUIScale = _listUIScale.clamp(_minListUIScale, _maxListUIScale);
      _gridUIScale = _gridUIScale.clamp(_minGridUIScale, _maxGridUIScale);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading icon size settings: $e');
      }
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_iconSizeKey}_list', _listIconSize);
      await prefs.setDouble('${_iconSizeKey}_grid', _gridIconSize);
      await prefs.setDouble('${_uiScaleKey}_list', _listUIScale);
      await prefs.setDouble('${_uiScaleKey}_grid', _gridUIScale);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving icon size settings: $e');
      }
    }
  }
  
  // Increase list icon size and UI scale (with upper limit)
  void increaseListIconSize() {
    final newSize = _listIconSize + _listResizeStep;
    if (newSize <= _maxListIconSize) {
      _listIconSize = newSize;
      // Proportionally adjust UI scale
      _listUIScale = (_listUIScale + _listUIScaleStep).clamp(_minListUIScale, _maxListUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Decrease list icon size (with lower limit)
  void decreaseListIconSize() {
    final newSize = _listIconSize - _listResizeStep;
    if (newSize >= _minListIconSize) {
      _listIconSize = newSize;
      // Proportionally adjust UI scale
      _listUIScale = (_listUIScale - _listUIScaleStep).clamp(_minListUIScale, _maxListUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Increase grid icon size (with upper limit)
  void increaseGridIconSize() {
    final newSize = _gridIconSize + _gridResizeStep;
    if (newSize <= _maxGridIconSize) {
      _gridIconSize = newSize;
      // Proportionally adjust UI scale
      _gridUIScale = (_gridUIScale + _gridUIScaleStep).clamp(_minGridUIScale, _maxGridUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Decrease grid icon size (with lower limit)
  void decreaseGridIconSize() {
    final newSize = _gridIconSize - _gridResizeStep;
    if (newSize >= _minGridIconSize) {
      _gridIconSize = newSize;
      // Proportionally adjust UI scale
      _gridUIScale = (_gridUIScale - _gridUIScaleStep).clamp(_minGridUIScale, _maxGridUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Handle scroll event for changing icon size
  void handleScroll(double delta, bool isGridView) {
    // Negative delta means scroll down (zoom out/decrease)
    // Positive delta means scroll up (zoom in/increase)
    if (delta < 0) {
      isGridView ? decreaseGridIconSize() : decreaseListIconSize();
    } else {
      isGridView ? increaseGridIconSize() : increaseListIconSize();
    }
  }
  
  // Reset to defaults
  void resetToDefaults() {
    _listIconSize = _defaultListIconSize;
    _gridIconSize = _defaultGridIconSize;
    _listUIScale = _defaultListUIScale;
    _gridUIScale = _defaultGridUIScale;
    _saveSettings();
    notifyListeners();
  }
} 