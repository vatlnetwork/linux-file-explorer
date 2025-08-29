import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              title: 'Theme Mode',
              child: _buildThemeSelector(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Accent Color',
              child: _buildAccentColorSelector(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Animations',
              child: _buildAnimationSettings(context, themeService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.grey[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }


  Widget _buildThemeSelector(BuildContext context, ThemeService themeService) {
    return SegmentedButton<ThemeMode>(
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
    );
  }

  Widget _buildAccentColorSelector(
    BuildContext context,
    ThemeService themeService,
  ) {
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          colors.map((color) {
            final isSelected = themeService.accentColor == color;
            return Material(
              elevation: isSelected ? 4 : 0,
              shape: CircleBorder(
                side: BorderSide(
                  color:
                      isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withAlpha(51),
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => themeService.setAccentColor(color),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child:
                      isSelected
                          ? Icon(
                            Icons.check,
                            color:
                                color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                          )
                          : null,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAnimationSettings(
    BuildContext context,
    ThemeService themeService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SwitchListTile(
      title: Text(
        'Enable Animations',
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'Enable or disable UI animations',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
        ),
      ),
      value: themeService.useAnimations,
      onChanged: (value) => themeService.setUseAnimations(value),
    );
  }

}
