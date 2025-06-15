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
              title: 'Theme Preset',
              child: _buildThemePresetSelector(context, themeService),
            ),
            const SizedBox(height: 24),
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
              title: 'Font Size',
              child: _buildFontSizeSettings(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Interface Density',
              child: _buildInterfaceSettings(context, themeService),
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

  Widget _buildThemePresetSelector(
    BuildContext context,
    ThemeService themeService,
  ) {
    return SegmentedButton<ThemePreset>(
      segments: const [
        ButtonSegment<ThemePreset>(
          value: ThemePreset.custom,
          label: Text('Custom'),
          icon: Icon(Icons.palette_outlined),
        ),
        ButtonSegment<ThemePreset>(
          value: ThemePreset.google,
          label: Text('Google'),
          icon: Icon(Icons.android),
        ),
        ButtonSegment<ThemePreset>(
          value: ThemePreset.macos,
          label: Text('macOS'),
          icon: Icon(Icons.laptop_mac),
        ),
      ],
      selected: {themeService.themePreset},
      onSelectionChanged: (Set<ThemePreset> selected) {
        themeService.setThemePreset(selected.first);
      },
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

  Widget _buildFontSizeSettings(
    BuildContext context,
    ThemeService themeService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value: themeService.fontSize,
              min: 12,
              max: 20,
              divisions: 8,
              label: '${themeService.fontSize.round()}px',
              onChanged: (value) => themeService.setFontSize(value),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${themeService.fontSize.round()}px',
              style: textTheme.bodySmall?.copyWith(
                color: isDarkMode ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceSettings(
    BuildContext context,
    ThemeService themeService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMacOS = themeService.themePreset == ThemePreset.macos;
    final switchColor = isMacOS ? const Color(0xFF34C759) : null;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Compact Mode',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              'Reduce spacing between elements',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            value: themeService.interfaceDensity > 0,
            onChanged:
                (value) => themeService.setInterfaceDensity(value ? 1 : 0),
            activeColor: switchColor,
            activeTrackColor: switchColor?.withValues(
              alpha: 0.5,
              red: switchColor.r,
              green: switchColor.g,
              blue: switchColor.b,
            ),
          ),
          if (themeService.interfaceDensity > 0) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Density Level',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: themeService.interfaceDensity,
                    min: 0,
                    max: 2,
                    divisions: 4,
                    label: themeService.interfaceDensity.toString(),
                    onChanged:
                        (value) => themeService.setInterfaceDensity(value),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
