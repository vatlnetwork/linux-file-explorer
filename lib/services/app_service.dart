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
  
  void setState(Function() fn) {
    fn();
    notifyListeners();
  }
} 