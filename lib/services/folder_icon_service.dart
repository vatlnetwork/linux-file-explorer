import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class FolderIconService {
  static final FolderIconService _instance = FolderIconService._internal();
  factory FolderIconService() => _instance;
  FolderIconService._internal();

  static const String _prefsKey = 'folder_icons';
  late SharedPreferences _prefs;
  final Map<String, String> _folderIcons = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFolderIcons();
  }

  void _loadFolderIcons() {
    final iconsJson = _prefs.getString(_prefsKey);
    if (iconsJson != null) {
      try {
        final Map<String, dynamic> iconsMap = Map<String, dynamic>.from(
          Map<String, dynamic>.from(iconsJson as Map)
        );
        _folderIcons.clear();
        iconsMap.forEach((key, value) {
          _folderIcons[key] = value.toString();
        });
      } catch (e) {
        // If there's an error loading the icons, clear the preferences
        _prefs.remove(_prefsKey);
      }
    }
  }

  Future<void> _saveFolderIcons() async {
    await _prefs.setString(_prefsKey, _folderIcons.toString());
  }

  /// Set a custom icon for a folder
  Future<void> setFolderIcon(String folderPath, String iconPath) async {
    if (!File(iconPath).existsSync()) {
      throw Exception('Icon file does not exist');
    }

    // Validate the icon file (should be an image)
    final ext = p.extension(iconPath).toLowerCase();
    if (!['.png', '.jpg', '.jpeg', '.gif', '.svg'].contains(ext)) {
      throw Exception('Invalid icon file format. Supported formats: PNG, JPG, GIF, SVG');
    }

    _folderIcons[folderPath] = iconPath;
    await _saveFolderIcons();
  }

  /// Remove custom icon for a folder
  Future<void> removeFolderIcon(String folderPath) async {
    _folderIcons.remove(folderPath);
    await _saveFolderIcons();
  }

  /// Get custom icon for a folder
  File? getFolderIcon(String folderPath) {
    final iconPath = _folderIcons[folderPath];
    return iconPath != null ? File(iconPath) : null;
  }

  /// Get all folders with custom icons
  Map<String, String> getAllCustomIcons() {
    return Map.from(_folderIcons);
  }

  /// Check if a folder has a custom icon
  bool hasCustomIcon(String folderPath) {
    return _folderIcons.containsKey(folderPath);
  }
} 