import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_item.dart';
import '../services/app_service.dart';
import '../services/notification_service.dart';
import '../services/file_association_service.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'system_icon.dart';

class AppSelectionDialog extends StatefulWidget {
  final String filePath;
  final String fileName;

  const AppSelectionDialog({
    Key? key,
    required this.filePath,
    required this.fileName,
  }) : super(key: key);

  @override
  State<AppSelectionDialog> createState() => _AppSelectionDialogState();

  // Helper method to show the dialog
  static Future<void> show(BuildContext context, String filePath) async {
    final fileName = p.basename(filePath);
    return showDialog(
      context: context,
      builder: (context) => AppSelectionDialog(
        filePath: filePath,
        fileName: fileName,
      ),
    );
  }
}

class _AppSelectionDialogState extends State<AppSelectionDialog> {
  bool _isSearching = false;
  String _searchQuery = '';
  bool _setAsDefault = false;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final appService = Provider.of<AppService>(context, listen: false);
    if (appService.apps.isEmpty) {
      appService.refreshApps();
    }
    
    // Check if there's already a default app for this file type
    final fileAssociationService = Provider.of<FileAssociationService>(context, listen: false);
    _setAsDefault = fileAssociationService.hasDefaultApp(widget.filePath);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Open file with the selected app
  Future<void> _openFileWithApp(AppItem app) async {
    try {
      // Extract the executable from the Exec field
      final executable = app.path;
      
      // If user wants to set this app as default, save the association
      if (_setAsDefault) {
        final fileAssociationService = Provider.of<FileAssociationService>(context, listen: false);
        final extension = p.extension(widget.filePath);
        await fileAssociationService.setDefaultApp(extension, app);
        
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Set ${app.name} as default app for $extension files',
            type: NotificationType.success,
          );
        }
      }
      
      // For .desktop files, use gtk-launch for better integration
      if (app.desktopFile.isNotEmpty) {
        // Launch using gtk-launch with the file as an argument
        final desktopFileName = app.desktopFile.split('/').last;
        final result = await Process.run('gtk-launch', [desktopFileName, widget.filePath]);
        
        if (result.exitCode != 0) {
          throw Exception('Failed to launch with gtk-launch: ${result.stderr}');
        }
      } else {
        // Direct launch using the executable
        await Process.run(executable, [widget.filePath]);
      }
      
      // Close the dialog after successful launch
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to open file: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  // Filter apps based on search query
  List<AppItem> _getFilteredApps(List<AppItem> apps) {
    if (_searchQuery.isEmpty) {
      return apps;
    }
    
    final query = _searchQuery.toLowerCase();
    return apps.where((app) => 
      app.name.toLowerCase().contains(query)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final fileAssociationService = Provider.of<FileAssociationService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<AppItem> filteredApps = _getFilteredApps(appService.apps);
    
    // Get the file extension
    final fileExtension = p.extension(widget.filePath);
    
    // Check if there's already a default app for this extension
    final String? defaultAppPath = fileAssociationService.getDefaultAppForFile(widget.filePath);
    AppItem? defaultApp;
    if (defaultAppPath != null) {
      defaultApp = appService.apps.firstWhere(
        (app) => app.desktopFile == defaultAppPath,
        orElse: () => AppItem(name: '', path: '', icon: '', desktopFile: ''),
      );
    }
    
    return AlertDialog(
      title: _isSearching 
        ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search applications...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _isSearching = false;
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          )
        : Row(
            children: [
              Expanded(
                child: Text('Open "${widget.fileName}" with:'),
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            ],
          ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show default app info if exists
          if (defaultApp != null && defaultApp.name.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default app for $fileExtension: ${defaultApp.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          SizedBox(
            width: 400,
            height: 350,
            child: appService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredApps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.app_blocking,
                          size: 64,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No applications found',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final isDefaultApp = defaultAppPath == app.desktopFile;
                      
                      return ListTile(
                        leading: SizedBox(
                          width: 24,
                          height: 24,
                          child: SystemIcon(
                            app: app,
                            size: 24,
                          ),
                        ),
                        title: Text(app.name),
                        subtitle: isDefaultApp 
                          ? Text('Default for $fileExtension', 
                              style: TextStyle(fontSize: 12, color: Colors.blue))
                          : null,
                        onTap: () => _openFileWithApp(app),
                      );
                    },
                  ),
          ),
          
          // "Set as default" checkbox
          if (!_isSearching && fileExtension.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _setAsDefault,
                    onChanged: (value) {
                      setState(() {
                        _setAsDefault = value ?? false;
                      });
                    },
                  ),
                  Text('Always use selected application for $fileExtension files'),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
} 