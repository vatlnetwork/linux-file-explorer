import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

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
    final primaryDisplay = await ScreenRetriever.instance.getPrimaryDisplay();

    final targetBounds =
        _isMaximized
            ? Rect.fromLTWH(
              0,
              0,
              primaryDisplay.size.width,
              primaryDisplay.size.height,
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

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isClose = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: 46,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose 
              ? const Color.fromRGBO(255, 0, 0, 0.2)
              : (isDarkMode ? const Color.fromRGBO(255, 255, 255, 0.1) : const Color.fromRGBO(0, 0, 0, 0.05)),
          highlightColor: Colors.transparent,
          splashColor: isClose 
              ? const Color.fromRGBO(255, 0, 0, 0.3)
              : (isDarkMode ? const Color.fromRGBO(255, 255, 255, 0.2) : const Color.fromRGBO(0, 0, 0, 0.1)),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: isClose 
                  ? Colors.red
                  : (isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultControls(bool isDarkMode) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF202124) : const Color(0xFFE8F0FE),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWindowButton(
            icon: Icons.minimize_rounded,
            onPressed: () => windowManager.minimize(),
          ),
          _buildWindowButton(
            icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
            onPressed: _toggleMaximize,
          ),
          _buildWindowButton(
            icon: Icons.close_rounded,
            onPressed: () => windowManager.close(),
            isClose: true,
          ),
        ],
      ),
    );
  }
}
