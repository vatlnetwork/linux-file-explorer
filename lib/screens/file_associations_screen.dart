import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../services/app_service.dart';
import '../services/file_association_service.dart';
import '../services/notification_service.dart';
import '../models/app_item.dart';
import '../widgets/system_icon.dart';

class FileAssociationsScreen extends StatefulWidget {
  const FileAssociationsScreen({super.key});

  @override
  State<FileAssociationsScreen> createState() => _FileAssociationsScreenState();
}

class _FileAssociationsScreenState extends State<FileAssociationsScreen> with WindowListener {
  bool _isMaximized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }
  
  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final fileAssociationService = Provider.of<FileAssociationService>(context);
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get all extensions that have default apps
    final List<String> extensions = fileAssociationService.getAllFileExtensions();
    extensions.sort((a, b) => a.compareTo(b)); // Sort alphabetically
    
    // Ensure the app service has loaded all apps
    if (appService.apps.isEmpty && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
      appService.refreshApps().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
    
    return Scaffold(
      body: Column(
        children: [
          // Title bar
          _buildTitleBar(context),
          
          // Main content
          Expanded(
            child: _isLoading || appService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : extensions.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _buildAssociationsList(context, extensions, fileAssociationService, appService),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? const Color(0xFF303030) 
        : const Color(0xFFBBDEFB);
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title and icon
          Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.settings_applications,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'File Type Associations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Window controls
          IconButton(
            icon: Icon(_isMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            onPressed: () {
              if (_isMaximized) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.settings_applications,
            size: 72,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
          const SizedBox(height: 16),
          Text(
            'No file type associations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you set default apps for file types, they will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssociationsList(
    BuildContext context, 
    List<String> extensions, 
    FileAssociationService fileAssociationService, 
    AppService appService
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default Applications by File Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage which applications open different file types by default.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: extensions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final extension = extensions[index];
                final defaultAppPath = fileAssociationService.fileAssociations[extension];
                
                // Find the app from the desktop file path
                AppItem? defaultApp;
                if (defaultAppPath != null) {
                  defaultApp = appService.apps.firstWhere(
                    (app) => app.desktopFile == defaultAppPath,
                    orElse: () => AppItem(name: 'Unknown App', path: '', icon: 'application', desktopFile: ''),
                  );
                }
                
                return ListTile(
                  leading: Icon(
                    Icons.description,
                    color: Colors.blue,
                  ),
                  title: Text(extension),
                  subtitle: defaultApp != null 
                    ? Row(
                        children: [
                          SizedBox(
                            width: 16, 
                            height: 16,
                            child: SystemIcon(
                              app: defaultApp,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(defaultApp.name),
                        ],
                      )
                    : Text('No default app set'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeAssociation(context, extension, fileAssociationService),
                    tooltip: 'Remove association',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _removeAssociation(BuildContext context, String extension, FileAssociationService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Association'),
        content: Text('Remove default app for $extension files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.removeDefaultApp(extension);
              Navigator.of(context).pop();
              NotificationService.showNotification(
                context,
                message: 'Removed default app for $extension files',
                type: NotificationType.success,
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
} 