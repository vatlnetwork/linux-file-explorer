import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildThemeSelector(context, themeService),
            const SizedBox(height: 16),
            _buildAccentColorSelector(context, themeService),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {themeService.themeMode},
          onSelectionChanged: (Set<ThemeMode> selected) {
            themeService.setThemeMode(selected.first);
          },
        ),
      ],
    );
  }

  Widget _buildAccentColorSelector(
    BuildContext context,
    ThemeService themeService,
  ) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accent Color',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              colors.map((color) {
                return InkWell(
                  onTap: () => themeService.setAccentColor(color),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            themeService.accentColor == color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
