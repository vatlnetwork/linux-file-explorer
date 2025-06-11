import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_item.dart';

class AppService extends ChangeNotifier {
  List<AppItem> _apps = [];
  static const String _storageKey = 'file_explorer_apps_cache';
  static const String _categoryStorageKey = 'file_explorer_app_categories';
  static const String _groupsStorageKey = 'file_explorer_app_groups';
  static const String _customCategoriesKey = 'custom_categories';
  static const String _sectionsStorageKey = 'custom_sections';
  static const String _sectionAppsStorageKey = 'section_apps';
  static const String _sectionIconsStorageKey = 'section_icons';
  bool _isLoading = false;
  DateTime? _lastRefresh;
  Map<String, String> _appCategories = {};
  Map<String, List<String>> _appGroups = {
    'Favorites': [],
    'Recently Added': [],
    'Most Used': [],
  };
  List<String> _customCategories = [];
  List<String> _customSections = [];
  Map<String, List<String>> _sectionApps = {};

  // Map to store resolved icon paths
  final Map<String, String?> _resolvedIconPaths = {};

  final Map<String, String> _iconMappings = {
    'Add Water': 'water',
    'Adobe Flash Player': 'flash',
    'Audio Player': 'audio',
    'Celluloid': 'celluloid',
    'Discord': 'discord',
    'Dolphin Emulator': 'dolphin-emu',
    'Extension Manager': 'org.gnome.Extensions',
    'Flatsweep': 'flatsweep',
    'Gear Lever': 'gear-lever',
    'GNOME Network Displays': 'org.gnome.NetworkDisplays',
    'Google Chrome': 'google-chrome',
    'Inspector': 'org.gnome.Info',
    'JamesDSP': 'jamesdsp',
    'Mission Center': 'org.gnome.SystemMonitor',
    'Mousam': 'org.gnome.Weather',
    'OnlyOffice': 'onlyoffice',
    'Planify': 'com.github.alainm23.planify',
    "Rosaline's Mupen GUI": 'mupen64plus',
    'Sly': 'org.gnome.Photos',
    'Visual Studio Code': 'code',
    'Windows Installer': 'wine',
    'Zen Browser': 'zen-browser',
    // Add more mappings as needed
  };

  // Default sections that cannot be removed
  final List<String> _defaultSections = [
    'Discover',
    'Create',
    'Work',
    'Play',
    'Develop',
    'Categories',
  ];

  // Map to store section icons with default icons for default sections
  final Map<String, String> _sectionIcons = {
    'Discover': 'explore',
    'Create': 'brush',
    'Work': 'work',
    'Play': 'games',
    'Develop': 'code',
    'Categories': 'category',
    'Add New Section': 'add',
  };

  // Getters
  List<AppItem> get apps => _apps;
  bool get isLoading => _isLoading;
  Map<String, List<String>> get appGroups => Map.unmodifiable(_appGroups);
  List<String> get customCategories => List.unmodifiable(_customCategories);
  List<String> get allSections => [..._defaultSections, ..._customSections];
  List<String> get customSections => List.unmodifiable(_customSections);
  bool isDefaultSection(String section) => _defaultSections.contains(section);

  // Get the category for an app
  String getAppCategory(AppItem app) {
    // First check if there's a custom category assignment
    if (_appCategories.containsKey(app.desktopFile)) {
      return _appCategories[app.desktopFile]!;
    }

    // Otherwise use the default category logic
    final name = app.name.toLowerCase();
    final path = app.path.toLowerCase();
    final desktop = app.desktopFile.toLowerCase();

    if (path.contains('system') || desktop.contains('system')) return 'System';
    if (path.contains('internet') ||
        name.contains('browser') ||
        name.contains('web')) {
      return 'Internet';
    }
    if (path.contains('dev') ||
        name.contains('code') ||
        name.contains('editor')) {
      return 'Development';
    }
    if (path.contains('graphics') ||
        name.contains('image') ||
        name.contains('photo')) {
      return 'Graphics';
    }
    if (name.contains('media') ||
        name.contains('video') ||
        name.contains('audio') ||
        name.contains('music') ||
        name.contains('player') ||
        name.contains('sound') ||
        name.contains('recorder')) {
      return 'Media';
    }
    if (path.contains('office') ||
        name.contains('doc') ||
        name.contains('calc')) {
      return 'Office';
    }
    if (path.contains('game') || desktop.contains('game')) return 'Games';
    return 'Other';
  }

  // Set a custom category for an app
  Future<void> setAppCategory(AppItem app, String category) async {
    _appCategories[app.desktopFile] = category;
    await _saveCategories();
    notifyListeners();
  }

  // Load saved category assignments
  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_categoryStorageKey);
      if (categoriesJson != null) {
        final Map<String, dynamic> decoded = json.decode(categoriesJson);
        _appCategories = Map<String, String>.from(decoded);
      }
    } catch (e) {
      debugPrint('Error loading app categories: $e');
    }
  }

  // Save category assignments
  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_categoryStorageKey, json.encode(_appCategories));
    } catch (e) {
      debugPrint('Error saving app categories: $e');
    }
  }

  // Reset an app's category to default
  Future<void> resetAppCategory(AppItem app) async {
    _appCategories.remove(app.desktopFile);
    await _saveCategories();
    notifyListeners();
  }

  // Get apps for a specific group
  List<AppItem> getAppsInGroup(String groupName) {
    final appPaths = _appGroups[groupName] ?? [];
    return _apps.where((app) => appPaths.contains(app.path)).toList();
  }

  // Add an app to a group
  Future<void> addAppToGroup(String groupName, AppItem app) async {
    if (!_appGroups.containsKey(groupName)) {
      _appGroups[groupName] = [];
    }
    if (!_appGroups[groupName]!.contains(app.path)) {
      _appGroups[groupName]!.add(app.path);
      await _saveGroups();
      notifyListeners();
    }
  }

  // Remove an app from a group
  Future<void> removeAppFromGroup(String groupName, AppItem app) async {
    if (_appGroups.containsKey(groupName)) {
      _appGroups[groupName]!.remove(app.path);
      await _saveGroups();
      notifyListeners();
    }
  }

  // Create a new group
  Future<void> createGroup(String groupName) async {
    if (!_appGroups.containsKey(groupName)) {
      _appGroups[groupName] = [];
      await _saveGroups();
      notifyListeners();
    }
  }

  // Delete a group
  Future<void> deleteGroup(String groupName) async {
    if (_appGroups.containsKey(groupName)) {
      _appGroups.remove(groupName);
      await _saveGroups();
      notifyListeners();
    }
  }

  // Load app groups from storage
  Future<void> _loadGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupsJson = prefs.getString(_groupsStorageKey);
      if (groupsJson != null) {
        final Map<String, dynamic> decoded = json.decode(groupsJson);
        _appGroups = Map<String, List<String>>.from(
          decoded.map(
            (key, value) =>
                MapEntry(key, (value as List<dynamic>).cast<String>()),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading app groups: $e');
    }
  }

  // Save app groups to storage
  Future<void> _saveGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groupsStorageKey, json.encode(_appGroups));
    } catch (e) {
      debugPrint('Error saving app groups: $e');
    }
  }

  // Custom category management
  Future<void> addCustomCategory(String category) async {
    if (!_customCategories.contains(category)) {
      _customCategories.add(category);
      await _saveCustomCategories();
      notifyListeners();
    }
  }

  Future<void> deleteCustomCategory(String category) async {
    if (_customCategories.contains(category)) {
      _customCategories.remove(category);
      // Remove this category from all apps
      _appCategories.removeWhere((key, value) => value == category);
      await _saveCustomCategories();
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> _loadCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_customCategoriesKey);
      if (categoriesJson != null) {
        final List<dynamic> decoded = json.decode(categoriesJson);
        _customCategories = decoded.cast<String>();
      }
    } catch (e) {
      debugPrint('Error loading custom categories: $e');
    }
  }

  Future<void> _saveCustomCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _customCategoriesKey,
        json.encode(_customCategories),
      );
    } catch (e) {
      debugPrint('Error saving custom categories: $e');
    }
  }

  // Section management
  Future<void> addSection(String section) async {
    if (!_customSections.contains(section) &&
        !_defaultSections.contains(section)) {
      _customSections.add(section);
      _sectionApps[section] = [];
      await _saveSections();
      notifyListeners();
    }
  }

  Future<void> deleteSection(String section) async {
    if (_customSections.contains(section)) {
      _customSections.remove(section);
      _sectionApps.remove(section);
      await _saveSections();
      notifyListeners();
    }
  }

  // App section assignment
  Future<void> addAppToSection(String section, AppItem app) async {
    if (!_sectionApps.containsKey(section)) {
      _sectionApps[section] = [];
    }
    if (!_sectionApps[section]!.contains(app.path)) {
      _sectionApps[section]!.add(app.path);
      await _saveSectionApps();
      notifyListeners();
    }
  }

  Future<void> removeAppFromSection(String section, AppItem app) async {
    if (_sectionApps.containsKey(section)) {
      _sectionApps[section]!.remove(app.path);
      await _saveSectionApps();
      notifyListeners();
    }
  }

  List<AppItem> getAppsInSection(String section) {
    if (section == 'Discover') {
      return _apps;
    }

    final appPaths = _sectionApps[section] ?? [];
    return _apps.where((app) => appPaths.contains(app.path)).toList();
  }

  // Load and save sections
  Future<void> _loadSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sectionsJson = prefs.getString(_sectionsStorageKey);
      final sectionAppsJson = prefs.getString(_sectionAppsStorageKey);

      if (sectionsJson != null) {
        final List<dynamic> decoded = json.decode(sectionsJson);
        _customSections = decoded.cast<String>();
      }

      if (sectionAppsJson != null) {
        final Map<String, dynamic> decoded = json.decode(sectionAppsJson);
        _sectionApps = decoded.map(
          (key, value) =>
              MapEntry(key, (value as List<dynamic>).cast<String>()),
        );
      }
    } catch (e) {
      debugPrint('Error loading sections: $e');
    }
  }

  Future<void> _saveSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sectionsStorageKey, json.encode(_customSections));
      await _saveSectionApps();
    } catch (e) {
      debugPrint('Error saving sections: $e');
    }
  }

  Future<void> _saveSectionApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sectionAppsStorageKey, json.encode(_sectionApps));
    } catch (e) {
      debugPrint('Error saving section apps: $e');
    }
  }

  // Get icon name for a section
  String getSectionIcon(String section) {
    // First check if it's a default section
    switch (section) {
      case 'Discover':
        return 'explore';
      case 'Create':
        return 'brush';
      case 'Work':
        return 'work';
      case 'Play':
        return 'games';
      case 'Develop':
        return 'code';
      case 'Categories':
        return 'category';
      case 'Add New Section':
        return 'add';
      default:
        return _sectionIcons[section] ?? 'folder';
    }
  }

  // Set icon for a section
  Future<void> setSectionIcon(String section, String iconName) async {
    _sectionIcons[section] = iconName;
    await _saveSectionIcons();
    notifyListeners();
  }

  // Load and save section icons
  Future<void> _loadSectionIcons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final iconsJson = prefs.getString(_sectionIconsStorageKey);
      if (iconsJson != null) {
        final Map<String, dynamic> decoded = json.decode(iconsJson);
        _sectionIcons.addAll(
          decoded.map((key, value) => MapEntry(key, value as String)),
        );
      }
    } catch (e) {
      debugPrint('Error loading section icons: $e');
    }
  }

  Future<void> _saveSectionIcons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sectionIconsStorageKey,
        json.encode(_sectionIcons),
      );
    } catch (e) {
      debugPrint('Error saving section icons: $e');
    }
  }

  // Initialize the service
  Future<void> initialize() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Initializing AppService...');
      await _loadCachedApps(); // First try to load cached apps
      await _loadSections();
      await _loadSectionIcons();
      await _loadCustomCategories();
      await _loadCategories();
      await refreshApps(); // Then refresh the apps list

      // Ensure default section icons are always set
      _sectionIcons.addAll({
        'Discover': 'explore',
        'Create': 'brush',
        'Work': 'work',
        'Play': 'games',
        'Develop': 'code',
        'Categories': 'category',
        'Add New Section': 'add',
      });
      await _saveSectionIcons();
    } catch (e) {
      debugPrint('Error initializing AppService: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load cached apps from shared preferences
  Future<void> _loadCachedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? appsJson = prefs.getString(_storageKey);
      final String? lastRefreshStr = prefs.getString(
        '${_storageKey}_timestamp',
      );

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
      await prefs.setString(
        '${_storageKey}_timestamp',
        _lastRefresh!.toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving apps: $e');
    }
  }

  // Refresh the list of installed applications
  Future<void> refreshApps() async {
    debugPrint('Starting app refresh...');
    if (_isLoading) {
      debugPrint('Skipping refresh - already loading');
      return;
    }

    if (_lastRefresh != null) {
      final difference = DateTime.now().difference(_lastRefresh!);
      if (difference.inMinutes < 5) {
        debugPrint(
          'Skipping refresh - last refresh was less than 5 minutes ago',
        );
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      List<AppItem> apps = [];

      // Get traditional desktop entries
      debugPrint('Loading desktop entries...');
      final desktopApps = await _getDesktopEntries();
      debugPrint('Found ${desktopApps.length} desktop applications');
      apps.addAll(desktopApps);

      // Get Flatpak applications
      debugPrint('Loading Flatpak applications...');
      final flatpakApps = await _getFlatpakApps();
      debugPrint('Found ${flatpakApps.length} Flatpak applications');
      apps.addAll(flatpakApps);

      // Get AppImage applications
      debugPrint('Loading AppImage applications...');
      final appImageApps = await _getAppImageApps();
      debugPrint('Found ${appImageApps.length} AppImage applications');
      apps.addAll(appImageApps);

      // Get DNF installed applications
      debugPrint('Loading DNF applications...');
      final dnfApps = await _getDnfApps();
      debugPrint('Found ${dnfApps.length} DNF applications');
      apps.addAll(dnfApps);

      // Remove duplicates based on app name
      final uniqueApps = <String, AppItem>{};
      for (final app in apps) {
        if (!uniqueApps.containsKey(app.name)) {
          uniqueApps[app.name] = app;
        }
      }

      _apps =
          uniqueApps.values.toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

      debugPrint('Total unique applications found: ${_apps.length}');
      await _saveApps();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing apps: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get traditional desktop entries
  Future<List<AppItem>> _getDesktopEntries() async {
    List<AppItem> apps = [];
    final List<String> locations = [
      '/usr/share/applications',
      '/usr/local/share/applications',
      '${Platform.environment['HOME']}/.local/share/applications',
    ];

    debugPrint('Scanning for desktop entries in: $locations');

    for (final location in locations) {
      final directory = Directory(location);
      if (!directory.existsSync()) {
        debugPrint('Directory does not exist: $location');
        continue;
      }

      debugPrint('Scanning directory: $location');
      try {
        final files = await directory.list().toList();
        debugPrint('Found ${files.length} files in $location');

        for (final file in files) {
          if (file.path.endsWith('.desktop')) {
            try {
              final desktopFile = File(file.path);
              final content = await desktopFile.readAsString();

              String? name;
              String? exec;
              String? icon;
              bool noDisplay = false;
              bool isSystemApp = false;
              bool hidden = false;
              String type = '';

              for (final line in content.split('\n')) {
                if (line.startsWith('Name=')) {
                  name = line.substring(5).trim();
                } else if (line.startsWith('Exec=')) {
                  exec = line.substring(5).trim();
                  // Keep the full command but clean up the field codes
                  exec =
                      exec.replaceAll(RegExp(r'%[fFuUdDnNickvm]'), '').trim();
                } else if (line.startsWith('Icon=')) {
                  icon = line.substring(5).trim();
                } else if (line.startsWith('NoDisplay=')) {
                  noDisplay = line.substring(10).trim().toLowerCase() == 'true';
                } else if (line.startsWith('Hidden=')) {
                  hidden = line.substring(7).trim().toLowerCase() == 'true';
                } else if (line.startsWith('Type=')) {
                  type = line.substring(5).trim();
                } else if (line.startsWith('Categories=')) {
                  isSystemApp =
                      line.contains('System') || line.contains('Settings');
                }
              }

              // Only add applications that:
              // 1. Have a name and exec command
              // 2. Are not explicitly hidden
              // 3. Are of type 'Application' or empty type (for backward compatibility)
              // 4. Have NoDisplay=false
              if (name != null &&
                  exec != null &&
                  !hidden &&
                  (type.isEmpty || type.toLowerCase() == 'application') &&
                  !noDisplay) {
                debugPrint(
                  'Adding application: $name (exec: $exec, icon: $icon)',
                );
                apps.add(
                  AppItem(
                    name: name,
                    path: exec,
                    icon: icon ?? 'application',
                    desktopFile: file.path,
                    isSystemApp: isSystemApp,
                  ),
                );
              } else {
                debugPrint(
                  'Skipping application: $name (hidden: $hidden, noDisplay: $noDisplay, type: $type)',
                );
              }
            } catch (e) {
              debugPrint('Error parsing desktop file ${file.path}: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning directory $location: $e');
      }
    }

    debugPrint('Found ${apps.length} desktop applications');
    return apps;
  }

  // Get Flatpak applications
  Future<List<AppItem>> _getFlatpakApps() async {
    List<AppItem> apps = [];
    try {
      final result = await Process.run('flatpak', [
        'list',
        '--app',
        '--columns=name,application,version',
      ]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final parts = line.split('\t');
          if (parts.length >= 2) {
            final name = parts[0].trim();
            final appId = parts[1].trim();
            apps.add(
              AppItem(
                name: name,
                path: 'flatpak run $appId',
                icon: appId,
                desktopFile: '/var/lib/flatpak/app/$appId',
                isFlatpak: true,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting Flatpak apps: $e');
    }
    return apps;
  }

  // Get AppImage applications
  Future<List<AppItem>> _getAppImageApps() async {
    List<AppItem> apps = [];
    final appImageLocations = [
      '${Platform.environment['HOME']}/.local/bin',
      '${Platform.environment['HOME']}/Applications',
      '/opt',
    ];

    for (final location in appImageLocations) {
      final directory = Directory(location);
      if (!directory.existsSync()) continue;

      try {
        await for (final file in directory.list(recursive: true)) {
          if (file.path.endsWith('.AppImage')) {
            final name = file.path.split('/').last.replaceAll('.AppImage', '');
            apps.add(
              AppItem(
                name: name,
                path: file.path,
                icon: 'application',
                desktopFile: file.path,
                isAppImage: true,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error scanning for AppImages in $location: $e');
      }
    }

    return apps;
  }

  // Get DNF installed applications
  Future<List<AppItem>> _getDnfApps() async {
    List<AppItem> apps = [];
    try {
      final result = await Process.run('dnf', ['list', 'installed']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        bool startParsing = false;

        for (final line in lines) {
          if (line.contains('Installed Packages')) {
            startParsing = true;
            continue;
          }

          if (startParsing && line.trim().isNotEmpty) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 2) {
              final name = parts[0].split('.').first;
              // Only add if it's likely to be an application
              if (_isLikelyApplication(name)) {
                apps.add(
                  AppItem(
                    name: _formatAppName(name),
                    path: name,
                    icon: 'application',
                    desktopFile: '',
                    isDnfPackage: true,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting DNF apps: $e');
    }
    return apps;
  }

  // Helper method to determine if a package is likely an application
  bool _isLikelyApplication(String packageName) {
    final keywords = [
      'app',
      'gui',
      'desktop',
      'game',
      'editor',
      'browser',
      'viewer',
      'player',
      'office',
      'ide',
      'tool',
      'suite',
    ];

    return keywords.any(
      (keyword) => packageName.toLowerCase().contains(keyword),
    );
  }

  // Helper method to format package names into readable app names
  String _formatAppName(String packageName) {
    // Split by hyphens and underscores
    final parts = packageName.split(RegExp(r'[-_]'));

    // Capitalize each part
    final formattedParts = parts.map((part) {
      if (part.isEmpty) return '';
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    });

    return formattedParts.join(' ');
  }

  // Launch application
  Future<bool> launchApp(AppItem app) async {
    try {
      if (app.isAppImage) {
        // Launch AppImage directly
        final result = await Process.run(app.path, []);
        return result.exitCode == 0;
      } else if (app.isFlatpak) {
        // Launch Flatpak app
        final parts = app.path.split(' ');
        final result = await Process.run(parts[0], parts.sublist(1));
        return result.exitCode == 0;
      } else {
        // For regular applications, use the exec command directly
        final parts = app.path.split(' ');
        final result = await Process.run(parts[0], parts.sublist(1));
        debugPrint('Launching app: ${app.name} with command: ${app.path}');
        return result.exitCode == 0;
      }
    } catch (e) {
      debugPrint('Error launching app ${app.name}: $e');
      return false;
    }
  }

  // Open a file with a specific application
  Future<bool> openFileWithApp(String filePath, String desktopFilePath) async {
    try {
      final desktopFileName = desktopFilePath.split('/').last;
      final result = await Process.run('gtk-launch', [
        desktopFileName,
        filePath,
      ]);
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Error opening file with app: $e');
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

    // Check if we have a mapping for this app
    final appName =
        _apps
            .firstWhere(
              (app) => app.icon == iconName,
              orElse:
                  () => AppItem(name: '', path: '', icon: '', desktopFile: ''),
            )
            .name;

    if (_iconMappings.containsKey(appName)) {
      iconName = _iconMappings[appName]!;
    }

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
          '/usr/share/icons/gnome',
          '/usr/share/icons/hicolor',
        ];

        // Common theme names and sizes to check
        final List<String> themes = [
          'Adwaita', // Prioritize Adwaita theme
          'hicolor',
          'gnome',
          'Papirus',
          'oxygen',
          'breeze',
          'elementary',
          'ubuntu-mono-dark',
          'ubuntu-mono-light',
        ];

        final List<String> sizes = [
          'scalable', // Prioritize scalable icons
          '256x256',
          '128x128',
          '96x96',
          '64x64',
          '48x48',
          '32x32',
        ];

        // Common file extensions
        final List<String> extensions = ['.svg', '.png', '.xpm'];

        // Check for symbolic icons first
        if (!iconName.endsWith('-symbolic')) {
          final symbolicName = '$iconName-symbolic';
          for (final iconPath in iconPaths) {
            for (final theme in themes) {
              for (final size in sizes) {
                for (final category in [
                  'apps',
                  'actions',
                  'mimetypes',
                  'places',
                  'devices',
                  'emblems',
                ]) {
                  for (final ext in extensions) {
                    final String testPath =
                        '$iconPath/$theme/$size/$category/$symbolicName$ext';
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

        // If symbolic icon not found, try regular icon
        if (resolvedPath == null) {
          // First check for direct matches in pixmaps
          for (final iconPath in iconPaths) {
            if (iconPath.contains('pixmaps')) {
              for (final ext in extensions) {
                final String testPath = '$iconPath/$iconName$ext';
                if (File(testPath).existsSync()) {
                  resolvedPath = testPath;
                  break;
                }
              }
            }
          }

          // Then check theme directories
          if (resolvedPath == null) {
            for (final iconPath in iconPaths) {
              for (final theme in themes) {
                for (final size in sizes) {
                  for (final category in [
                    'apps',
                    'actions',
                    'mimetypes',
                    'places',
                    'devices',
                    'emblems',
                  ]) {
                    for (final ext in extensions) {
                      final String testPath =
                          '$iconPath/$theme/$size/$category/$iconName$ext';
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
        }

        // If still not found, try to find a similar icon name
        if (resolvedPath == null) {
          for (final iconPath in iconPaths) {
            if (iconPath.contains('pixmaps')) {
              final directory = Directory(iconPath);
              if (directory.existsSync()) {
                final files = directory.listSync();
                for (final file in files) {
                  if (file is File) {
                    final fileName = file.path.split('/').last;
                    if (fileName.startsWith(iconName) ||
                        fileName.contains(iconName)) {
                      resolvedPath = file.path;
                      break;
                    }
                  }
                }
              }
            }
            if (resolvedPath != null) break;
          }
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
