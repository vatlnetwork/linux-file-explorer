import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeSwitcher extends StatelessWidget {
  final bool useCustomColors;
  
  const ThemeSwitcher({
    super.key,
    this.useCustomColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final Color iconColor = useCustomColors ? Colors.white : Theme.of(context).iconTheme.color ?? Colors.grey;
    
    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        _getThemeIcon(themeService.themeMode),
        color: iconColor,
      ),
      tooltip: 'Change theme',
      onSelected: (ThemeMode mode) {
        themeService.setThemeMode(mode);
      },
      itemBuilder: (context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: _buildMenuItem(
            context: context,
            icon: Icons.brightness_auto,
            text: 'System Theme',
            isSelected: themeService.isSystemMode,
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: _buildMenuItem(
            context: context,
            icon: Icons.brightness_7,
            text: 'Light Theme',
            isSelected: themeService.isLightMode,
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: _buildMenuItem(
            context: context,
            icon: Icons.brightness_4,
            text: 'Dark Theme',
            isSelected: themeService.isDarkMode,
          ),
        ),
      ],
    );
  }
  
  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_4;
    }
  }
  
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon, 
    required String text, 
    required bool isSelected,
  }) {
    return Row(
      children: [
        Icon(
          icon, 
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ],
    );
  }
} 