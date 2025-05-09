import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';

class Tab {
  final String id;
  String path;
  String title;
  bool isLoading;
  bool hasError;
  String errorMessage;

  Tab({
    required this.id,
    required this.path,
    required this.title,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
  });

  Tab copyWith({
    String? path,
    String? title,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return Tab(
      id: id,
      path: path ?? this.path,
      title: title ?? this.title,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TabManagerService extends ChangeNotifier {
  final List<Tab> _tabs = [];
  int _currentTabIndex = 0;
  bool _showTabBar = false;

  List<Tab> get tabs => List.unmodifiable(_tabs);
  int get currentTabIndex => _currentTabIndex;
  Tab? get currentTab => _tabs.isNotEmpty ? _tabs[_currentTabIndex] : null;
  bool get showTabBar => _showTabBar;

  void addTab(String path, {String? title}) {
    final newTab = Tab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      title: title ?? p.basename(path),
    );
    _tabs.add(newTab);
    _currentTabIndex = _tabs.length - 1;
    _showTabBar = true;
    notifyListeners();
  }

  void removeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    
    _tabs.removeAt(index);
    if (_currentTabIndex >= _tabs.length) {
      _currentTabIndex = _tabs.length - 1;
    }
    notifyListeners();

    // If this was the last tab, close the window
    if (_tabs.isEmpty) {
      windowManager.close();
    }
  }

  void closeAllTabs() {
    _tabs.clear();
    _currentTabIndex = 0;
    notifyListeners();
    windowManager.close();
  }

  void switchTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  void updateTab(int index, Tab updatedTab) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs[index] = updatedTab;
    notifyListeners();
  }

  void updateCurrentTabPath(String path) {
    if (_tabs.isEmpty) return;
    final currentTab = _tabs[_currentTabIndex];
    _tabs[_currentTabIndex] = currentTab.copyWith(
      path: path,
      title: p.basename(path),
    );
    notifyListeners();
  }

  void updateCurrentTabLoading(bool isLoading) {
    if (_tabs.isEmpty) return;
    final currentTab = _tabs[_currentTabIndex];
    _tabs[_currentTabIndex] = currentTab.copyWith(isLoading: isLoading);
    notifyListeners();
  }

  void updateCurrentTabError(bool hasError, String errorMessage) {
    if (_tabs.isEmpty) return;
    final currentTab = _tabs[_currentTabIndex];
    _tabs[_currentTabIndex] = currentTab.copyWith(
      hasError: hasError,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  void setShowTabBar(bool show) {
    if (_showTabBar != show) {
      _showTabBar = show;
      notifyListeners();
    }
  }
} 