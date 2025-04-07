import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode {
  list,
  grid,
  split,
}

class ViewModeService extends ChangeNotifier {
  static const String _viewModeKey = 'view_mode';

  ViewMode _viewMode = ViewMode.list;

  ViewMode get viewMode => _viewMode;

  bool get isList => _viewMode == ViewMode.list;
  bool get isGrid => _viewMode == ViewMode.grid;
  bool get isSplit => _viewMode == ViewMode.split;

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
        default:
          _viewMode = ViewMode.list;
          break;
      }
      notifyListeners();
    }
  }

  Future<void> setViewMode(ViewMode mode) async {
    if (_viewMode == mode) return;

    _viewMode = mode;
    notifyListeners();

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
    }

    await prefs.setString(_viewModeKey, modeString);
  }
} 