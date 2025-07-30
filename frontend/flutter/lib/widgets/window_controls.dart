import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls>
    with SingleTickerProviderStateMixin {
  bool _isMaximized = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Size? _previousSize;
  Offset? _previousPosition;

  @override
  void initState() {
    super.initState();
    _initWindowState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _animation.addListener(() {
      _updateWindowSize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  Future<void> _updateWindowSize() async {
    if (_previousSize == null || _previousPosition == null) return;

    final currentBounds = await windowManager.getBounds();

    final targetBounds =
        _isMaximized
            ? Rect.fromLTWH(
              0,
              0,
              windowManager.getPrimaryDisplay().size.width,
              windowManager.getPrimaryDisplay().size.height,
            )
            : Rect.fromLTWH(
              _previousPosition!.dx,
              _previousPosition!.dy,
              _previousSize!.width,
              _previousSize!.height,
            );

    final interpolatedBounds = Rect.lerp(
      currentBounds,
      targetBounds,
      _animation.value,
    );

    if (interpolatedBounds != null) {
      await windowManager.setBounds(interpolatedBounds);
    }
  }

  Future<void> _toggleMaximize() async {
    if (!_isMaximized) {
      // Store current size and position before maximizing
      final bounds = await windowManager.getBounds();
      _previousSize = Size(bounds.width, bounds.height);
      _previousPosition = Offset(bounds.left, bounds.top);

      _animationController.forward();
      await windowManager.maximize();
    } else {
      _animationController.reverse();
      await windowManager.unmaximize();
    }

    _isMaximized = !_isMaximized;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Remove themeService and themePreset logic
    return _buildDefaultControls(isDarkMode);
  }

  Widget _buildDefaultControls(bool isDarkMode) {
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
          onPressed: _toggleMaximize,
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
}
