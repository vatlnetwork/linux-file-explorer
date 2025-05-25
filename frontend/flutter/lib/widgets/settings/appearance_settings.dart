import 'package:flutter/material.dart';

class AppearanceSettings extends StatefulWidget {
  const AppearanceSettings({super.key});

  @override
  State<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends State<AppearanceSettings> {
  String _selectedTheme = 'system';
  Color _selectedAccentColor = Colors.blue;

  final List<Color> _accentColors = [
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Theme Selection
          _buildSection(
            title: 'Theme',
            child: Column(
              children: [
                _buildThemeOption(
                  title: 'System',
                  value: 'system',
                  subtitle: 'Follow system theme',
                  icon: Icons.brightness_auto,
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: 'Light',
                  value: 'light',
                  subtitle: 'Light theme',
                  icon: Icons.light_mode,
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  title: 'Dark',
                  value: 'dark',
                  subtitle: 'Dark theme',
                  icon: Icons.dark_mode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Accent Color Selection
          _buildSection(
            title: 'Accent Color',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  _accentColors.map((color) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAccentColor = color;
                        });
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _selectedAccentColor == color
                                    ? Colors.white
                                    : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            if (_selectedAccentColor == color)
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child:
                            _selectedAccentColor == color
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTheme == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTheme = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
            ),
            color:
                isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : isDarkMode
                        ? Colors.white
                        : Colors.grey.shade800,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : isDarkMode
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
