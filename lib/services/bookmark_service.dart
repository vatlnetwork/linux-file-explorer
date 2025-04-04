import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_item.dart';
import '../models/file_item.dart';

class BookmarkService extends ChangeNotifier {
  List<BookmarkItem> _bookmarks = [];
  static const String _storageKey = 'file_explorer_bookmarks';

  List<BookmarkItem> get bookmarks => _bookmarks;

  // Initialize the service and load bookmarks from storage
  Future<void> init() async {
    await _loadBookmarks();
  }

  // Load bookmarks from shared preferences
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bookmarksJson = prefs.getString(_storageKey);
      
      if (bookmarksJson != null) {
        final List<dynamic> decoded = jsonDecode(bookmarksJson);
        _bookmarks = decoded.map((item) => BookmarkItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
    }
  }

  // Save bookmarks to shared preferences
  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String bookmarksJson = jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
      await prefs.setString(_storageKey, bookmarksJson);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  // Add a bookmark
  Future<void> addBookmark(FileItem item) async {
    // Only allow directories to be bookmarked
    if (item.type != FileItemType.directory) return;

    // Check if already bookmarked
    if (_bookmarks.any((b) => b.path == item.path)) return;

    _bookmarks.add(BookmarkItem.fromFileItem(item));
    notifyListeners();
    await _saveBookmarks();
  }

  // Remove a bookmark
  Future<void> removeBookmark(String path) async {
    _bookmarks.removeWhere((b) => b.path == path);
    notifyListeners();
    await _saveBookmarks();
  }

  // Check if a path is bookmarked
  bool isBookmarked(String path) {
    return _bookmarks.any((b) => b.path == path);
  }
  
  // Reorder bookmarks
  Future<void> reorderBookmarks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      // Removing the item at oldIndex will shorten the list by 1
      newIndex -= 1;
    }
    
    final BookmarkItem item = _bookmarks.removeAt(oldIndex);
    _bookmarks.insert(newIndex, item);
    
    notifyListeners();
    await _saveBookmarks();
  }
} 