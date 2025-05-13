import 'package:flutter/material.dart';

class FileExplorerState extends ChangeNotifier {
  String _currentPath = '';
  Set<String> _selectedItemsPaths = {};
  bool _isLoading = false;
  bool _showBookmarkSidebar = true;
  final List<String> _navigationHistory = [];
  final List<String> _forwardHistory = [];
  final List<String> _bookmarks = [];
  
  String get currentPath => _currentPath;
  Set<String> get selectedItemsPaths => _selectedItemsPaths;
  bool get isLoading => _isLoading;
  bool get showBookmarkSidebar => _showBookmarkSidebar;
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  List<String> get forwardHistory => List.unmodifiable(_forwardHistory);
  List<String> get bookmarks => List.unmodifiable(_bookmarks);
  
  void setCurrentPath(String path) {
    if (_currentPath != path) {
      _navigationHistory.add(_currentPath);
      _forwardHistory.clear();
      _currentPath = path;
      notifyListeners();
    }
  }
  
  void navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      _forwardHistory.add(_currentPath);
      _currentPath = _navigationHistory.removeLast();
      notifyListeners();
    }
  }
  
  void navigateForward() {
    if (_forwardHistory.isNotEmpty) {
      _navigationHistory.add(_currentPath);
      _currentPath = _forwardHistory.removeLast();
      notifyListeners();
    }
  }
  
  void setSelectedItems(Set<String> paths) {
    _selectedItemsPaths = paths;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void toggleBookmarkSidebar() {
    _showBookmarkSidebar = !_showBookmarkSidebar;
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedItemsPaths.clear();
    notifyListeners();
  }
  
  void addToSelection(String path) {
    _selectedItemsPaths.add(path);
    notifyListeners();
  }
  
  void removeFromSelection(String path) {
    _selectedItemsPaths.remove(path);
    notifyListeners();
  }
  
  void addBookmark(String path) {
    if (!_bookmarks.contains(path)) {
      _bookmarks.add(path);
      notifyListeners();
    }
  }
  
  void removeBookmark(String path) {
    _bookmarks.remove(path);
    notifyListeners();
  }
} 