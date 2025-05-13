import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/app_item.dart';

class FileAssociationService extends ChangeNotifier {
  // Storage key for file type associations
  static const String _storageKey = 'file_explorer_file_associations';
  
  // Map of file extensions to app desktop file paths
  Map<String, String> _fileAssociations = {};
  
  // Getter for associations
  Map<String, String> get fileAssociations => _fileAssociations;
  
  // Initialize the service
  Future<void> init() async {
    await _loadAssociations();
  }
  
  // Load file associations from SharedPreferences
  Future<void> _loadAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? associationsJson = prefs.getString(_storageKey);
      
      if (associationsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(associationsJson);
        _fileAssociations = decoded.map(
          (key, value) => MapEntry(key, value.toString())
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading file associations: $e');
    }
  }
  
  // Save file associations to SharedPreferences
  Future<void> _saveAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String associationsJson = jsonEncode(_fileAssociations);
      await prefs.setString(_storageKey, associationsJson);
    } catch (e) {
      debugPrint('Error saving file associations: $e');
    }
  }
  
  // Set a default app for a file extension
  Future<void> setDefaultApp(String fileExtension, AppItem app) async {
    // Normalize extension (ensure it starts with a dot)
    final normalizedExtension = fileExtension.startsWith('.')
        ? fileExtension
        : '.$fileExtension';
    
    // Store the association using the desktop file path
    _fileAssociations[normalizedExtension] = app.desktopFile;
    notifyListeners();
    await _saveAssociations();
  }
  
  // Remove a default app association
  Future<void> removeDefaultApp(String fileExtension) async {
    // Normalize extension
    final normalizedExtension = fileExtension.startsWith('.')
        ? fileExtension
        : '.$fileExtension';
    
    if (_fileAssociations.containsKey(normalizedExtension)) {
      _fileAssociations.remove(normalizedExtension);
      notifyListeners();
      await _saveAssociations();
    }
  }
  
  // Get the default app desktop file path for a file
  String? getDefaultAppForFile(String filePath) {
    final fileExtension = p.extension(filePath).toLowerCase();
    return _fileAssociations[fileExtension];
  }
  
  // Check if a file has a default app association
  bool hasDefaultApp(String filePath) {
    final fileExtension = p.extension(filePath).toLowerCase();
    return _fileAssociations.containsKey(fileExtension);
  }
  
  // Get all file extensions with default apps
  List<String> getAllFileExtensions() {
    return _fileAssociations.keys.toList();
  }
} 