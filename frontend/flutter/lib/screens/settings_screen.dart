import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/settings/appearance_settings.dart';
import '../widgets/settings/addons_settings.dart';
import '../widgets/settings/about_settings.dart';
import '../services/theme_service.dart';
import '../services/settings_view_mode_service.dart';
import 'disk_manager_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0;

  final List<_SettingsSection> _sections = [
    _SettingsSection(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      widget: const AppearanceSettings(),
      description: 'Customize the look and feel of your file explorer',
    ),
    _SettingsSection(
      title: 'Disk Manager',
      icon: Icons.storage_outlined,
      widget: const DiskManagerScreen(),
      description: 'Monitor and manage disk usage and storage',
    ),
    _SettingsSection(
      title: 'Addons',
      icon: Icons.extension_outlined,
      widget: const AddonsSettings(),
      description: 'Manage context menu items and file explorer extensions',
    ),
    _SettingsSection(
      title: 'About',
      icon: Icons.info_outline,
      widget: const AboutSettings(),
      description: 'View app information and helpful resources',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeService = context.watch<ThemeService>();
    final viewModeService = context.watch<SettingsViewModeService>();
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final sidebarColor =
        isDarkMode ? const Color(0xFF252525) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Sidebar spanning full height
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: sidebarColor,
              border: Border(
                right: BorderSide(
                  color: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Column(
              children: [
                // Settings sections list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = _selectedIndex == index;
                      return _buildSidebarItem(
                        section: section,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main content area with its own header
          Expanded(
            child: Column(
              children: [
                // Title bar in main content
                Container(
                  height: 40,
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // View mode toggle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF3D3D3D)
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.view_agenda_outlined,
                                size: 18,
                                color:
                                    viewModeService.viewMode ==
                                            SettingsViewMode.comfortable
                                        ? Theme.of(context).colorScheme.primary
                                        : isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                              ),
                              tooltip: 'Comfortable view',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed:
                                  () => viewModeService.setViewMode(
                                    SettingsViewMode.comfortable,
                                  ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.view_compact_outlined,
                                size: 18,
                                color:
                                    viewModeService.viewMode ==
                                            SettingsViewMode.compact
                                        ? Theme.of(context).colorScheme.primary
                                        : isDarkMode
                                        ? Colors.white70
                                        : Colors.grey.shade800,
                              ),
                              tooltip: 'Compact view',
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed:
                                  () => viewModeService.setViewMode(
                                    SettingsViewMode.compact,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Theme toggle
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF3D3D3D)
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: InkWell(
                          onTap: () => themeService.toggleTheme(),
                          borderRadius: BorderRadius.circular(6),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            size: 18,
                            color:
                                isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Section description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _sections[_selectedIndex].icon,
                            size: viewModeService.getIconSize(),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sections[_selectedIndex].title,
                            style: TextStyle(
                              fontSize: viewModeService.getTitleFontSize(),
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sections[_selectedIndex].description,
                        style: TextStyle(
                          fontSize:
                              viewModeService.viewMode ==
                                      SettingsViewMode.comfortable
                                  ? 14
                                  : 12,
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(child: _sections[_selectedIndex].widget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required _SettingsSection section,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? isDarkMode
                        ? Colors.grey[800]
                        : Colors.white
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border:
                isSelected && !isDarkMode
                    ? Border.all(color: Colors.blue.shade400, width: 1.5)
                    : null,
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 16,
                color:
                    isSelected
                        ? isDarkMode
                            ? Colors.white
                            : Colors.black
                        : isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isSelected
                            ? isDarkMode
                                ? Colors.white
                                : Colors.black
                            : isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  final Widget widget;
  final String description;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.widget,
    required this.description,
  });
}
