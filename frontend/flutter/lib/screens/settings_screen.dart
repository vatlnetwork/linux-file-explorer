import 'package:flutter/material.dart';
import '../widgets/settings/appearance_settings.dart';
import '../widgets/settings/addons_settings.dart';
import '../widgets/settings/about_settings.dart';

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
    ),
    _SettingsSection(
      title: 'Addons',
      icon: Icons.extension_outlined,
      widget: const AddonsSettings(),
    ),
    _SettingsSection(
      title: 'About',
      icon: Icons.info_outline,
      widget: const AboutSettings(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Panel
          Container(
            width: 250,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color:
                      isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Tooltip(
                            message: 'Back to File Explorer',
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
                      const SizedBox(width: 12),
                      Icon(
                        Icons.settings,
                        size: 20,
                        color:
                            isDarkMode ? Colors.white70 : Colors.grey.shade800,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = _selectedIndex == index;

                      return ListTile(
                        leading: Icon(
                          section.icon,
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade800,
                        ),
                        title: Text(
                          section.title,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(child: _sections[_selectedIndex].widget),
        ],
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  final Widget widget;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.widget,
  });
}
