import 'package:flutter/material.dart';
import '../models/file_item.dart';

class TabService extends ChangeNotifier {
  final List<String> _paths = [];
  final List<String> _titles = [];
  int _currentIndex = 0;

  List<String> get paths => List.unmodifiable(_paths);
  List<String> get titles => List.unmodifiable(_titles);
  int get currentIndex => _currentIndex;
  int get tabCount => _paths.length;

  void addTab(String path, {String? title}) {
    _paths.add(path);
    _titles.add(title ?? path);
    _currentIndex = _paths.length - 1;
    notifyListeners();
  }

  void removeTab(int index) {
    if (index < 0 || index >= _paths.length) return;

    _paths.removeAt(index);
    _titles.removeAt(index);

    if (_currentIndex >= _paths.length) {
      _currentIndex = _paths.length - 1;
    }

    notifyListeners();
  }

  void switchTab(int index) {
    if (index < 0 || index >= _paths.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  void updateTabPath(int index, String path, {String? title}) {
    if (index < 0 || index >= _paths.length) return;
    _paths[index] = path;
    if (title != null) {
      _titles[index] = title;
    }
    notifyListeners();
  }

  String getCurrentPath() {
    if (_paths.isEmpty) return '';
    return _paths[_currentIndex];
  }

  void closeAllTabs() {
    _paths.clear();
    _titles.clear();
    _currentIndex = -1;
    notifyListeners();
  }
} 