import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../services/disk_usage_widget_service.dart';

class ContextMenuSettings extends ChangeNotifier {
  final Map<String, bool> _contextMenuItems = {
    'open': true, // Open
    'open_with': true, // Open with...
    'copy': true, // Copy
    'cut': true, // Cut
    'paste': true, // Paste
    'delete': true, // Delete
    'rename': true, // Rename
    'properties': true, // Properties
    'bookmark': true, // Add/Remove Bookmark (folders only)
    'terminal': true, // Open in Terminal (folders only)
    'compress': true, // Compress
    'extract': true, // Extract (compressed files only)
    'markup': false, // Markup Editor (images only)
  };

  bool isEnabled(String key) => _contextMenuItems[key] ?? true;

  void toggleOption(String key) {
    if (_contextMenuItems.containsKey(key)) {
      _contextMenuItems[key] = !_contextMenuItems[key]!;
      notifyListeners();
    }
  }
}

class AddonsSettings extends StatelessWidget {
  const AddonsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AddonsSettingsContent();
  }
}

class _AddonsSettingsContent extends StatelessWidget {
  const _AddonsSettingsContent();

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<ContextMenuSettings>(context);
    final diskUsageService = Provider.of<DiskUsageWidgetService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final isMacOS = themeService.themePreset == ThemePreset.macos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Addons',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Context Menu Items
          _buildSection(
            context: context,
            title: 'Context Menu Items',
            subtitle: 'Choose which items appear in the right-click menu',
            child: _buildContextMenuCard(
              context,
              settings,
              isDarkMode,
              isMacOS,
            ),
          ),

          const SizedBox(height: 24),

          // Interface Elements
          _buildSection(
            context: context,
            title: 'Interface Elements',
            subtitle: 'Configure visibility of interface elements',
            child: Card(
              elevation: 0,
              color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interface Elements',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toggle visibility of various interface elements',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.storage,
                      color:
                          diskUsageService.showDiskUsageWidget
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor,
                    ),
                    title: const Text('Disk Usage Widget'),
                    subtitle: const Text(
                      'Show disk usage information at the bottom of the sidebar',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: diskUsageService.showDiskUsageWidget,
                      onChanged:
                          (value) =>
                              diskUsageService.setShowDiskUsageWidget(value),
                      activeColor:
                          isMacOS
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                      activeTrackColor:
                          isMacOS
                              ? const Color(0xFF34C759).withValues(
                                red: 52,
                                green: 199,
                                blue: 89,
                                alpha: 0.5,
                              )
                              : null,
                      inactiveThumbColor:
                          isDarkMode ? Colors.grey.shade400 : Colors.white,
                      inactiveTrackColor:
                          isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.drag_indicator,
                      color:
                          settings.isEnabled('drag_drop_dialog')
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor,
                    ),
                    title: const Text('Drag and Drop Dialog'),
                    subtitle: const Text(
                      'Show dialog when dragging and dropping files',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: settings.isEnabled('drag_drop_dialog'),
                      onChanged:
                          (value) => settings.toggleOption('drag_drop_dialog'),
                      activeColor:
                          isMacOS
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                      activeTrackColor:
                          isMacOS
                              ? const Color(0xFF34C759).withValues(
                                red: 52,
                                green: 199,
                                blue: 89,
                                alpha: 0.5,
                              )
                              : null,
                      inactiveThumbColor:
                          isDarkMode ? Colors.grey.shade400 : Colors.white,
                      inactiveTrackColor:
                          isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenuCard(
    BuildContext context,
    ContextMenuSettings settings,
    bool isDarkMode,
    bool isMacOS,
  ) {
    return Card(
      elevation: 0,
      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Context Menu Items',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize which items appear in the context menu',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: settings._contextMenuItems.length,
            separatorBuilder:
                (context, index) => Divider(
                  height: 1,
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
            itemBuilder: (context, index) {
              final key = settings._contextMenuItems.keys.elementAt(index);
              final isEnabled = settings._contextMenuItems[key]!;

              return ListTile(
                leading: Icon(
                  _getItemIcon(key),
                  color:
                      isEnabled
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                ),
                title: Text(_getItemTitle(key)),
                subtitle: Text(
                  _getItemDescription(key),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (value) => settings.toggleOption(key),
                  activeColor:
                      isMacOS ? Colors.white : Theme.of(context).primaryColor,
                  activeTrackColor:
                      isMacOS
                          ? const Color(0xFF34C759).withValues(
                            red: 52,
                            green: 199,
                            blue: 89,
                            alpha: 0.5,
                          )
                          : null,
                  inactiveThumbColor:
                      isDarkMode ? Colors.grey.shade400 : Colors.white,
                  inactiveTrackColor:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  String _getItemDescription(String key) {
    switch (key) {
      case 'open':
        return 'Open files with default application';
      case 'open_with':
        return 'Choose application to open files';
      case 'copy':
        return 'Copy selected items';
      case 'cut':
        return 'Cut selected items';
      case 'paste':
        return 'Paste items from clipboard';
      case 'delete':
        return 'Delete selected items';
      case 'rename':
        return 'Rename selected item';
      case 'properties':
        return 'View item properties';
      case 'bookmark':
        return 'Add or remove folder bookmarks';
      case 'terminal':
        return 'Open folder in terminal';
      case 'compress':
        return 'Create compressed archive';
      case 'extract':
        return 'Extract compressed files';
      case 'markup':
        return 'Edit images with markup tools';
      default:
        return '';
    }
  }

  IconData _getItemIcon(String key) {
    switch (key) {
      case 'open':
        return Icons.open_in_new;
      case 'open_with':
        return Icons.apps;
      case 'copy':
        return Icons.copy;
      case 'cut':
        return Icons.cut;
      case 'paste':
        return Icons.paste;
      case 'delete':
        return Icons.delete;
      case 'rename':
        return Icons.edit;
      case 'properties':
        return Icons.info_outline;
      case 'bookmark':
        return Icons.bookmark_outline;
      case 'terminal':
        return Icons.terminal;
      case 'compress':
        return Icons.archive;
      case 'extract':
        return Icons.unarchive;
      case 'markup':
        return Icons.brush;
      default:
        return Icons.extension;
    }
  }

  String _getItemTitle(String key) {
    switch (key) {
      case 'open':
        return 'Open';
      case 'open_with':
        return 'Open With...';
      case 'copy':
        return 'Copy';
      case 'cut':
        return 'Cut';
      case 'paste':
        return 'Paste';
      case 'delete':
        return 'Delete';
      case 'rename':
        return 'Rename';
      case 'properties':
        return 'Properties';
      case 'bookmark':
        return 'Bookmarks';
      case 'terminal':
        return 'Terminal';
      case 'compress':
        return 'Compress';
      case 'extract':
        return 'Extract';
      case 'markup':
        return 'Markup Editor';
      default:
        return key;
    }
  }
}
