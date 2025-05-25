import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/settings/appearance_settings.dart';
import '../widgets/settings/addons_settings.dart';
import '../widgets/settings/about_settings.dart';
import '../services/theme_service.dart';

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

    return Scaffold(
      body: Container(
        color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
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
                    color: Colors.black.withAlpha(13),
                    blurRadius: 1,
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
                                  : const Color(0xFFF0F0F0),
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
                                  : const Color(0xFFF0F0F0),
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
                  NavigationRail(
                    backgroundColor:
                        isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
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
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _sections[_selectedIndex].icon,
                                      size: 24,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _sections[_selectedIndex].title,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _sections[_selectedIndex].description,
                                  style: TextStyle(
                                    fontSize: 14,
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
