import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_item.dart';

class AppService extends ChangeNotifier {
  List<AppItem> _apps = [];
  static const String _storageKey = 'file_explorer_apps_cache';
  bool _isLoading = false;
  DateTime? _lastRefresh;
  
  // Map to store resolved icon paths
  final Map<String, String?> _resolvedIconPaths = {};

  List<AppItem> get apps => _apps;
  bool get isLoading => _isLoading;

  // Initialize the service and load apps
  Future<void> init() async {
    _loadCachedApps();
    await refreshApps();
  }

  // Load cached apps from shared preferences
  Future<void> _loadCachedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appsJson = prefs.getString(_storageKey);
      final String? lastRefreshStr = prefs.getString('${_storageKey}_timestamp');
      
      if (lastRefreshStr != null) {
        _lastRefresh = DateTime.parse(lastRefreshStr);
      }
      
      if (appsJson != null) {
        final List<dynamic> decoded = jsonDecode(appsJson);
        _apps = decoded.map((item) => AppItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached apps: $e');
    }
  }

  // Save apps to shared preferences
  Future<void> _saveApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String appsJson = jsonEncode(_apps.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, appsJson);
      
      // Save timestamp
      _lastRefresh = DateTime.now();
      await prefs.setString('${_storageKey}_timestamp', _lastRefresh!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving apps: $e');
    }
  }

  // Refresh the list of installed applications
  Future<void> refreshApps() async {
    // Avoid refreshing too frequently
    if (_isLoading) return;
    if (_lastRefresh != null) {
      final difference = DateTime.now().difference(_lastRefresh!);
      if (difference.inMinutes < 5) return; // Only refresh every 5 minutes
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For Linux, use the 'gtk-launch' command to get desktop entries
      final List<AppItem> apps = await _getInstalledApps();
      
      _apps = apps;
      await _saveApps();
      
      setState(() {
        _isLoading = false;
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing apps: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Get installed applications on Linux
  Future<List<AppItem>> _getInstalledApps() async {
    List<AppItem> apps = [];
    
    try {
      // Look for .desktop files in standard locations
      final List<String> locations = [
        '/usr/share/applications',
        '/usr/local/share/applications',
        '${Platform.environment['HOME']}/.local/share/applications',
      ];
      
      for (final location in locations) {
        final directory = Directory(location);
        if (!directory.existsSync()) continue;
        
        await for (final file in directory.list()) {
          if (file.path.endsWith('.desktop')) {
            try {
              final desktopFile = File(file.path);
              final content = await desktopFile.readAsString();
              
              // Parse the .desktop file
              String? name;
              String? exec;
              String? icon;
              bool noDisplay = false;
              
              for (final line in content.split('\n')) {
                if (line.startsWith('Name=')) {
                  name = line.substring(5);
                } else if (line.startsWith('Exec=')) {
                  exec = line.substring(5);
                  // Remove any arguments
                  exec = exec.split(' ').first.replaceAll(RegExp(r'%[a-zA-Z]'), '');
                } else if (line.startsWith('Icon=')) {
                  icon = line.substring(5);
                } else if (line.startsWith('NoDisplay=true')) {
                  noDisplay = true;
                }
              }
              
              // Only add applications that should be displayed
              if (name != null && exec != null && !noDisplay) {
                apps.add(AppItem(
                  name: name,
                  path: exec,
                  icon: icon ?? 'application',
                  desktopFile: file.path,
                ));
              }
            } catch (e) {
              debugPrint('Error parsing desktop file ${file.path}: $e');
            }
          }
        }
      }
      
      // Sort by name
      apps.sort((a, b) => a.name.compareTo(b.name));
      
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
    }
    
    return apps;
  }
  
  // Launch application by desktop file
  Future<bool> launchApp(AppItem app) async {
    try {
      final result = await Process.run('gtk-launch', [app.desktopFile.split('/').last]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error launching app: $e');
      return false;
    }
  }
  
  // Find the actual path for an icon by name
  Future<String?> getIconPath(String iconName) async {
    // Check if we've already resolved this icon
    if (_resolvedIconPaths.containsKey(iconName)) {
      return _resolvedIconPaths[iconName];
    }
    
    String? resolvedPath;
    
    try {
      // First check if the iconName is an absolute path and exists
      if (iconName.startsWith('/') && File(iconName).existsSync()) {
        resolvedPath = iconName;
      } else {
        // Standard icon search paths
        final List<String> iconPaths = [
          '/usr/share/icons',
          '/usr/share/pixmaps',
          '/usr/local/share/icons',
          '${Platform.environment['HOME']}/.local/share/icons',
        ];
        
        // Common theme names and sizes to check
        final List<String> themes = [
          'hicolor',
          'Adwaita',
          'gnome',
          'oxygen',
          'breeze',
          'Papirus',
        ];
        
        final List<String> sizes = [
          '48x48',
          '64x64',
          '32x32',
          '128x128',
          'scalable',
        ];
        
        // Common file extensions
        final List<String> extensions = [
          '.png', 
          '.svg', 
          '.xpm',
        ];
        
        // Check theme icon directories
        for (final iconPath in iconPaths) {
          // First check for direct matches in pixmaps
          if (iconPath.contains('pixmaps')) {
            for (final ext in extensions) {
              final String testPath = '$iconPath/$iconName$ext';
              if (File(testPath).existsSync()) {
                resolvedPath = testPath;
                break;
              }
            }
          }
          
          // Check in theme directories
          for (final theme in themes) {
            for (final size in sizes) {
              // For most themes, icons are in {theme}/{size}/{category}
              // Common categories
              for (final category in ['apps', 'actions', 'mimetypes', 'places']) {
                for (final ext in extensions) {
                  final String testPath = '$iconPath/$theme/$size/$category/$iconName$ext';
                  if (File(testPath).existsSync()) {
                    resolvedPath = testPath;
                    break;
                  }
                }
                
                if (resolvedPath != null) break;
              }
              
              if (resolvedPath != null) break;
            }
            
            if (resolvedPath != null) break;
          }
          
          if (resolvedPath != null) break;
        }
      }
    } catch (e) {
      debugPrint('Error resolving icon path for $iconName: $e');
    }
    
    // Cache the result
    _resolvedIconPaths[iconName] = resolvedPath;
    return resolvedPath;
  }
  
  // Check if an icon file exists and is readable
  Future<bool> hasValidIcon(AppItem app) async {
    final iconPath = await getIconPath(app.icon);
    if (iconPath == null) return false;
    
    try {
      return File(iconPath).existsSync();
    } catch (e) {
      return false;
    }
  }
  
  void setState(Function() fn) {
    fn();
    notifyListeners();
  }
} 