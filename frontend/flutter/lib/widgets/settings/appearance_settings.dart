import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
              title: 'Font Settings',
              child: _buildFontSettings(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Icon Settings',
              child: _buildIconSettings(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Interface Density',
              child: _buildInterfaceSettings(context, themeService),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: 'Animation Settings',
              child: _buildAnimationSettings(context, themeService),
            ),
            if (themeService.themePreset == ThemePreset.custom) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                title: 'Custom Colors',
                child: _buildCustomColorSettings(context, themeService),
              ),
            ],
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
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withAlpha(51)
                    : Colors.grey.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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

  Widget _buildFontSettings(BuildContext context, ThemeService themeService) {
    final fonts = ['Roboto', 'Inter', 'SF Pro Text', 'Helvetica Neue', 'Arial'];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: themeService.fontFamily,
            decoration: InputDecoration(
              labelText: 'Font Family',
              labelStyle: textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
            ),
            items:
                fonts.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(
                      font,
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: font,
                        color: isDarkMode ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  );
                }).toList(),
            onChanged: (value) {
              if (value != null) themeService.setFontFamily(value);
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
              Text(
                'Font Size',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
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
        ),
      ],
    );
  }

  Widget _buildIconSettings(BuildContext context, ThemeService themeService) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          Text(
            'Icon Weight',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          Expanded(
            child: Slider(
              value: themeService.iconWeight,
              min: 100,
              max: 700,
              divisions: 6,
              label: themeService.iconWeight.round().toString(),
              onChanged: (value) => themeService.setIconWeight(value),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              themeService.iconWeight.round().toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          Icon(
            Icons.compress,
            size: 20,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
          Expanded(
            child: Slider(
              value: themeService.interfaceDensity,
              min: -2,
              max: 2,
              divisions: 4,
              onChanged: (value) => themeService.setInterfaceDensity(value),
            ),
          ),
          Icon(
            Icons.expand,
            size: 20,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimationSettings(
    BuildContext context,
    ThemeService themeService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: isDarkMode ? Colors.white : Colors.grey[800],
        ),
        child: SwitchListTile(
          title: Text(
            'Enable Animations',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          subtitle: Text(
            'Smooth transitions between screens and states',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          value: themeService.useAnimations,
          onChanged: (value) => themeService.setUseAnimations(value),
        ),
      ),
    );
  }

  Widget _buildCustomColorSettings(
    BuildContext context,
    ThemeService themeService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in themeService.customColors.entries)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: ListTile(
              title: Text(
                entry.key.toUpperCase(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.grey[800],
                ),
              ),
              trailing: Material(
                elevation: 2,
                shape: CircleBorder(
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                child: InkWell(
                  onTap:
                      () => _showColorPicker(context, themeService, entry.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showColorPicker(
    BuildContext context,
    ThemeService themeService,
    String colorKey,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Pick ${colorKey.toUpperCase()} Color',
              style: textTheme.titleLarge?.copyWith(
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: themeService.customColors[colorKey]!,
                onColorChanged:
                    (color) => themeService.setCustomColor(colorKey, color),
                pickerAreaHeightPercent: 0.8,
                enableAlpha: false,
                labelTypes: const [],
                displayThumbColor: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Done',
                  style: textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
