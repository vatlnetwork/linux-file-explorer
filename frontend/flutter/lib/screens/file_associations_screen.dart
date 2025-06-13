import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _FileAssociationsScreenState extends State<FileAssociationsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileAssociationService = Provider.of<FileAssociationService>(context);
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get all extensions that have default apps
    final List<String> extensions =
        fileAssociationService.getAllFileExtensions();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [const Color(0xFF2D2D2D), const Color(0xFF1A1A1A)]
                    : [const Color(0xFFE8F0FE), const Color(0xFFF5F9FF)],
          ),
        ),
        child: Column(
          children: [
            // Modern header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF303030) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 16),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_applications,
                    color: Colors.blue.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File Type Associations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child:
                  _isLoading || appService.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : extensions.isEmpty
                      ? _buildEmptyState(isDarkMode)
                      : _buildAssociationsList(
                        context,
                        extensions,
                        fileAssociationService,
                        appService,
                        isDarkMode,
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssociationDialog(context),
        backgroundColor: Colors.blue.shade400,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? Colors.blue.shade900.withValues(alpha: 51)
                        : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_applications,
                size: 64,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No File Associations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set default applications for your file types',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociationsList(
    BuildContext context,
    List<String> extensions,
    FileAssociationService fileAssociationService,
    AppService appService,
    bool isDarkMode,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Applications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage which applications open different file types',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: extensions.length,
                itemBuilder: (context, index) {
                  final extension = extensions[index];
                  final defaultAppPath =
                      fileAssociationService.fileAssociations[extension];

                  AppItem? defaultApp;
                  if (defaultAppPath != null) {
                    defaultApp = appService.apps.firstWhere(
                      (app) => app.desktopFile == defaultAppPath,
                      orElse:
                          () => AppItem(
                            name: 'Unknown App',
                            path: '',
                            icon: 'application',
                            desktopFile: '',
                          ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 0,
                    color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color:
                            isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.blue.shade900.withValues(alpha: 51)
                                  : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          extension,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color:
                                isDarkMode
                                    ? Colors.blue.shade300
                                    : Colors.blue.shade700,
                          ),
                        ),
                      ),
                      title:
                          defaultApp != null
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
                                  const SizedBox(width: 6),
                                  Text(
                                    defaultApp.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                'No default app set',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                ),
                              ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                        onPressed:
                            () => _removeAssociation(
                              context,
                              extension,
                              fileAssociationService,
                            ),
                        tooltip: 'Remove association',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeAssociation(
    BuildContext context,
    String extension,
    FileAssociationService service,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Association'),
            content: Text('Remove default app for $extension files?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
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
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _showAddAssociationDialog(BuildContext context) {
    final fileAssociationService = Provider.of<FileAssociationService>(
      context,
      listen: false,
    );
    final appService = Provider.of<AppService>(context, listen: false);

    String extension = '';
    AppItem? selectedApp;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add File Association'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'File Extension',
                          hintText: 'e.g., .txt, .pdf',
                        ),
                        onChanged: (value) => extension = value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AppItem>(
                        decoration: const InputDecoration(
                          labelText: 'Default Application',
                        ),
                        items:
                            appService.apps.map((app) {
                              return DropdownMenuItem(
                                value: app,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: SystemIcon(app: app, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(app.name),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (app) => setState(() => selectedApp = app),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        if (extension.isNotEmpty && selectedApp != null) {
                          fileAssociationService.setDefaultApp(
                            extension,
                            selectedApp!,
                          );
                          Navigator.of(context).pop();
                          NotificationService.showNotification(
                            context,
                            message: 'Added default app for $extension files',
                            type: NotificationType.success,
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }
}
