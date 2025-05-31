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
    final viewMode = viewModeService.viewMode;

    return Scaffold(
      body: Container(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF0F2F5),
        child: Column(
          children: [
            // Custom app bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDarkMode ? 40 : 20),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF3D3D3D)
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  // View options
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.view_agenda_outlined,
                            size: 20,
                            color:
                                viewMode == SettingsViewMode.comfortable
                                    ? Theme.of(context).colorScheme.primary
                                    : isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade800,
                          ),
                          tooltip: 'Comfortable view',
                          onPressed:
                              () => viewModeService.setViewMode(
                                SettingsViewMode.comfortable,
                              ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.view_compact_outlined,
                            size: 20,
                            color:
                                viewMode == SettingsViewMode.compact
                                    ? Theme.of(context).colorScheme.primary
                                    : isDarkMode
                                    ? Colors.white70
                                    : Colors.grey.shade800,
                          ),
                          tooltip: 'Compact view',
                          onPressed:
                              () => viewModeService.setViewMode(
                                SettingsViewMode.compact,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Theme toggle button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => themeService.toggleTheme(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? const Color(0xFF3D3D3D)
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Navigation rail
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDarkMode ? 40 : 20),
                          blurRadius: 2,
                          offset: const Offset(1, 0),
                        ),
                      ],
                    ),
                    child: NavigationRail(
                      backgroundColor: Colors.transparent,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      labelType: NavigationRailLabelType.none,
                      useIndicator: true,
                      indicatorColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(26),
                      destinations:
                          _sections.map((section) {
                            return NavigationRailDestination(
                              icon: Icon(section.icon),
                              selectedIcon: Icon(
                                section.icon,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(section.title),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            );
                          }).toList(),
                    ),
                  ),
                  // Section title and content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDarkMode ? 40 : 20),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Container(
                            padding: viewModeService.getContentPadding(),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[200]!,
                                  width: 1,
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    SizedBox(
                                      width:
                                          viewMode ==
                                                  SettingsViewMode.comfortable
                                              ? 12
                                              : 8,
                                    ),
                                    Text(
                                      _sections[_selectedIndex].title,
                                      style: TextStyle(
                                        fontSize:
                                            viewModeService.getTitleFontSize(),
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      viewMode == SettingsViewMode.comfortable
                                          ? 8
                                          : 4,
                                ),
                                Text(
                                  _sections[_selectedIndex].description,
                                  style: TextStyle(
                                    fontSize:
                                        viewMode == SettingsViewMode.comfortable
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
                          // Section content
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              child: _sections[_selectedIndex].widget,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
