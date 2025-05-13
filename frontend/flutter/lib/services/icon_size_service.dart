import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

class IconSizeService extends ChangeNotifier {
  static const String _iconSizeKey = 'icon_size';
  static const String _uiScaleKey = 'ui_scale';
  
  // Default sizes for list and grid views
  static const double _defaultListIconSize = 24.0;
  static const double _defaultGridIconSize = 48.0;
  
  // Default UI scale factors
  static const double _defaultListUIScale = 1.0;
  static const double _defaultGridUIScale = 1.0;
  
  // Size constraints - making these public for external use
  static const double minListIconSize = 16.0;
  static const double maxListIconSize = 48.0;
  static const double minGridIconSize = 24.0;
  static const double maxGridIconSize = 96.0;
  
  // UI scale constraints - making these public for external use
  static const double minListUIScale = 0.7;
  static const double maxListUIScale = 1.5;
  static const double minGridUIScale = 0.7;
  static const double maxGridUIScale = 1.4;
  
  // Step sizes for resizing
  static const double _listResizeStep = 4.0;
  static const double _gridResizeStep = 8.0;
  
  // Step sizes for UI scaling - making these public for external use
  static const double listUIScaleStep = 0.1;
  static const double gridUIScaleStep = 0.1;
  
  double _listIconSize = _defaultListIconSize;
  double _gridIconSize = _defaultGridIconSize;
  double _listUIScale = _defaultListUIScale;
  double _gridUIScale = _defaultGridUIScale;
  
  double get listIconSize => _listIconSize.clamp(minListIconSize, maxListIconSize);
  double get gridIconSize => _gridIconSize.clamp(minGridIconSize, maxGridIconSize);
  double get listUIScale => _listUIScale.clamp(minListUIScale, maxListUIScale);
  double get gridUIScale => _gridUIScale.clamp(minGridUIScale, maxGridUIScale);
  
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
  
  // Get the maximum number of items that can fit in a given width with consistent sizing
  int getMaxItemsInWidth(double availableWidth) {
    // Calculate how many items can fit at current scale
    return (availableWidth / gridItemExtent).floor().clamp(1, 12);
  }
  
  // Get width-adaptive grid delegate that maintains consistent item sizes
  SliverGridDelegateWithFixedCrossAxisCount getConsistentSizeGridDelegate(
    double availableWidth, {
    int minimumColumns = 3,
    double childAspectRatio = 0.9,
    double spacing = 10.0,
  }) {
    // Base item size to maintain consistency
    final itemWidth = gridItemExtent;
    
    // Calculate max columns based on fixed item size
    int maxColumns = (availableWidth / itemWidth).floor();
    
    // Ensure we meet minimum columns requirement
    int columns = maxColumns.clamp(minimumColumns, 12);
    
    // Safety check to prevent negative or zero columns
    if (columns <= 0) columns = minimumColumns;
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
    );
  }
  
  // Get responsive grid item size based on available width
  double getResponsiveGridItemExtent(double availableWidth, int targetItemCount) {
    // Default size
    double baseExtent = gridItemExtent;
    
    // Calculate how many items would fit with the default size
    int itemsFit = (availableWidth / baseExtent).floor();
    
    // If we can fit fewer items than target, scale down the size to fit more
    if (itemsFit < targetItemCount && itemsFit > 0) {
      // Scale factor to fit more items, but never below minimum
      double scaleFactor = (availableWidth / (targetItemCount * 120.0))
          .clamp(minGridUIScale, maxGridUIScale);
      
      return 120.0 * scaleFactor;
    }
    
    return baseExtent;
  }
  
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
      _listIconSize = _listIconSize.clamp(minListIconSize, maxListIconSize);
      _gridIconSize = _gridIconSize.clamp(minGridIconSize, maxGridIconSize);
      _listUIScale = _listUIScale.clamp(minListUIScale, maxListUIScale);
      _gridUIScale = _gridUIScale.clamp(minGridUIScale, maxGridUIScale);
      
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
    if (newSize <= maxListIconSize) {
      _listIconSize = newSize;
      // Proportionally adjust UI scale
      _listUIScale = (_listUIScale + listUIScaleStep).clamp(minListUIScale, maxListUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Decrease list icon size (with lower limit)
  void decreaseListIconSize() {
    final newSize = _listIconSize - _listResizeStep;
    if (newSize >= minListIconSize) {
      _listIconSize = newSize;
      // Proportionally adjust UI scale
      _listUIScale = (_listUIScale - listUIScaleStep).clamp(minListUIScale, maxListUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Increase grid icon size (with upper limit)
  void increaseGridIconSize() {
    final newSize = _gridIconSize + _gridResizeStep;
    if (newSize <= maxGridIconSize) {
      _gridIconSize = newSize;
      // Proportionally adjust UI scale
      _gridUIScale = (_gridUIScale + gridUIScaleStep).clamp(minGridUIScale, maxGridUIScale);
      _saveSettings();
      notifyListeners();
    }
  }
  
  // Decrease grid icon size (with lower limit)
  void decreaseGridIconSize() {
    final newSize = _gridIconSize - _gridResizeStep;
    if (newSize >= minGridIconSize) {
      _gridIconSize = newSize;
      // Proportionally adjust UI scale
      _gridUIScale = (_gridUIScale - gridUIScaleStep).clamp(minGridUIScale, maxGridUIScale);
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