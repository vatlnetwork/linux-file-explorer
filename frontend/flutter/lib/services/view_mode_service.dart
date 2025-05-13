import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode {
  list,
  grid,
  split,
  column,
}

class ViewModeService extends ChangeNotifier {
  static const String _viewModeKey = 'view_mode';

  ViewMode _viewMode = ViewMode.list;
  ViewMode? _previousViewMode;

  ViewMode get viewMode => _viewMode;
  ViewMode? get previousViewMode => _previousViewMode;

  bool get isList => _viewMode == ViewMode.list;
  bool get isGrid => _viewMode == ViewMode.grid;
  bool get isSplit => _viewMode == ViewMode.split;
  bool get isColumn => _viewMode == ViewMode.column;

  ViewModeService() {
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_viewModeKey);

    if (savedMode != null) {
      switch (savedMode) {
        case 'list':
          _viewMode = ViewMode.list;
          break;
        case 'grid':
          _viewMode = ViewMode.grid;
          break;
        case 'split':
          _viewMode = ViewMode.split;
          break;
        case 'column':
          _viewMode = ViewMode.column;
          break;
        default:
          _viewMode = ViewMode.list;
          break;
      }
      notifyListeners();
    }
  }

  Future<void> setViewMode(ViewMode mode) async {
    if (_viewMode == mode) return;

    // Store the previous view mode for clean transitions
    _previousViewMode = _viewMode;
    _viewMode = mode;
    
    // Notify listeners with a small delay to allow previous view widgets to clean up
    await Future.delayed(const Duration(milliseconds: 10));
    notifyListeners();

    // Save the new view mode preference
    _saveViewModePreference(mode);
  }
  
  // Clean transition from one view mode to another
  Future<void> transitionToViewMode(ViewMode mode) async {
    if (_viewMode == mode) return;
    
    // Store the current view mode before changing
    final oldMode = _viewMode;
    _previousViewMode = oldMode;
    
    // First notify listeners that we're transitioning to ensure cleanup
    _viewMode = ViewMode.list; // Temporarily set to list view as a safe intermediate
    notifyListeners();
    
    // Brief pause to allow for cleanup
    await Future.delayed(const Duration(milliseconds: 25));
    
    // Now set to the actual target mode
    _viewMode = mode;
    notifyListeners();
    
    // Save the preference
    _saveViewModePreference(mode);
  }
  
  // Save view mode preference to shared preferences
  Future<void> _saveViewModePreference(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;

    switch (mode) {
      case ViewMode.list:
        modeString = 'list';
        break;
      case ViewMode.grid:
        modeString = 'grid';
        break;
      case ViewMode.split:
        modeString = 'split';
        break;
      case ViewMode.column:
        modeString = 'column';
        break;
    }

    await prefs.setString(_viewModeKey, modeString);
  }
} 