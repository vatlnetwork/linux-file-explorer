import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _initWindowState();
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (themeService.themePreset == ThemePreset.macos) {
      return _buildMacOSControls(isDarkMode);
    } else {
      return _buildGoogleControls(isDarkMode);
    }
  }

  Widget _buildMacOSControls(bool isDarkMode) {
    final closeColor =
        isDarkMode ? const Color(0xFFFF5F57) : const Color(0xFFFF5F57);
    final minimizeColor =
        isDarkMode ? const Color(0xFFFFBD2E) : const Color(0xFFFFBD2E);
    final maximizeColor =
        isDarkMode ? const Color(0xFF28C940) : const Color(0xFF28C940);

    return Row(
      children: [
        _buildMacOSButton(
          color: maximizeColor,
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            _isMaximized = !_isMaximized;
            setState(() {});
          },
          icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
          showIcon: false,
        ),
        const SizedBox(width: 8),
        _buildMacOSButton(
          color: minimizeColor,
          onPressed: () async {
            await windowManager.minimize();
          },
          icon: Icons.remove,
          showIcon: false,
        ),
        const SizedBox(width: 8),
        _buildMacOSButton(
          color: closeColor,
          onPressed: () async {
            await windowManager.close();
          },
          icon: Icons.close,
          showIcon: false,
        ),
      ],
    );
  }

  Widget _buildMacOSButton({
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
    required bool showIcon,
  }) {
    return MouseRegion(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: showIcon ? Icon(icon, size: 10, color: Colors.black54) : null,
        ),
      ),
    );
  }

  Widget _buildGoogleControls(bool isDarkMode) {
    final iconColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          iconSize: 20,
          splashRadius: 16,
          color: iconColor,
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        IconButton(
          icon: Icon(_isMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
          iconSize: 20,
          splashRadius: 16,
          color: iconColor,
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
            _isMaximized = !_isMaximized;
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          iconSize: 20,
          splashRadius: 16,
          color: iconColor,
          onPressed: () async {
            await windowManager.close();
          },
        ),
      ],
    );
  }
}
