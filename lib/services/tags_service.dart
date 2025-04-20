import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tag.dart';

class TagsService extends ChangeNotifier {
  static const String _tagsKey = 'file_tags';
  static const String _allTagsKey = 'all_tags';
  
  /// Map of file paths to list of tag IDs
  Map<String, List<String>> _fileTags = {};
  
  /// List of all available tags
  List<Tag> _availableTags = [];
  
  /// Get all available tags
  List<Tag> get availableTags => _availableTags;
  
  TagsService() {
    _loadTags();
  }
  
  /// Load tags from shared preferences
  Future<void> _loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load file tags
    final fileTagsJson = prefs.getString(_tagsKey);
    if (fileTagsJson != null) {
      try {
        final Map<String, dynamic> fileTagsMap = json.decode(fileTagsJson);
        _fileTags = fileTagsMap.map((key, value) {
          if (value is List) {
            return MapEntry(key, List<String>.from(value));
          } else {
            return MapEntry(key, <String>[]);
          }
        });
      } catch (e) {
        _fileTags = {};
      }
    }
    
    // Load available tags
    final availableTagsJson = prefs.getString(_allTagsKey);
    if (availableTagsJson != null) {
      try {
        final List<dynamic> availableTagsList = json.decode(availableTagsJson);
        _availableTags = availableTagsList
          .map((tagJson) => Tag.fromMap(tagJson))
          .toList();
      } catch (e) {
        _availableTags = CommonTags.getAll();
      }
    } else {
      // Initialize with common tags
      _availableTags = CommonTags.getAll();
    }
    
    notifyListeners();
  }
  
  /// Save tags to shared preferences
  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save file tags
    final fileTagsJson = json.encode(_fileTags);
    await prefs.setString(_tagsKey, fileTagsJson);
    
    // Save available tags
    final availableTagsJson = json.encode(
      _availableTags.map((tag) => tag.toMap()).toList()
    );
    await prefs.setString(_allTagsKey, availableTagsJson);
  }
  
  /// Get tags for a file
  List<Tag> getTagsForFile(String filePath) {
    final tagIds = _fileTags[filePath] ?? [];
    return _availableTags
      .where((tag) => tagIds.contains(tag.id))
      .toList();
  }
  
  /// Add a tag to a file
  Future<void> addTagToFile(String filePath, Tag tag) async {
    // Make sure the tag is in the available tags
    if (!_availableTags.any((t) => t.id == tag.id)) {
      _availableTags.add(tag);
    }
    
    // Add the tag to the file
    if (!_fileTags.containsKey(filePath)) {
      _fileTags[filePath] = [];
    }
    
    if (!_fileTags[filePath]!.contains(tag.id)) {
      _fileTags[filePath]!.add(tag.id);
    }
    
    await _saveTags();
    notifyListeners();
  }
  
  /// Remove a tag from a file
  Future<void> removeTagFromFile(String filePath, String tagId) async {
    if (_fileTags.containsKey(filePath)) {
      _fileTags[filePath]!.remove(tagId);
      
      // Remove the file entry if there are no tags
      if (_fileTags[filePath]!.isEmpty) {
        _fileTags.remove(filePath);
      }
      
      await _saveTags();
      notifyListeners();
    }
  }
  
  /// Create a new tag
  Future<Tag> createTag(String name, Color color) async {
    final tag = Tag.create(name: name, color: color);
    _availableTags.add(tag);
    await _saveTags();
    notifyListeners();
    return tag;
  }
  
  /// Delete a tag
  Future<void> deleteTag(String tagId) async {
    // Remove the tag from the list of available tags
    _availableTags.removeWhere((tag) => tag.id == tagId);
    
    // Remove the tag from all files
    for (final filePath in _fileTags.keys) {
      _fileTags[filePath]!.remove(tagId);
      
      // Remove the file entry if there are no tags
      if (_fileTags[filePath]!.isEmpty) {
        _fileTags.remove(filePath);
      }
    }
    
    await _saveTags();
    notifyListeners();
  }
  
  /// Check if a file has a specific tag
  bool fileHasTag(String filePath, String tagId) {
    return _fileTags[filePath]?.contains(tagId) ?? false;
  }
  
  /// Get all files with a specific tag
  List<String> getFilesWithTag(String tagId) {
    final List<String> files = [];
    
    for (final entry in _fileTags.entries) {
      if (entry.value.contains(tagId)) {
        files.add(entry.key);
      }
    }
    
    return files;
  }
} 