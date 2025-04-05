import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/color_extensions.dart';
import '../services/theme_service.dart';

class WindowTitleBar extends StatefulWidget {
  final String title;
  final Widget child;

  const WindowTitleBar({super.key, required this.title, required this.child});

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark =
        themeService.isDarkMode ||
        (themeService.isSystemMode &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildTitleBar(isDark),
          Expanded(child: widget.child),
          _buildResizeHandles(),
        ],
      ),
    );
  }

  Widget _buildTitleBar(bool isDark) {
    return GestureDetector(
      onPanStart: (details) {
        windowManager.startDragging();
      },
      onDoubleTap: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.folder, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            _buildWindowControls(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowControls(bool isDark) {
    return Row(
      children: [
        _buildControlButton(
          icon: Icons.minimize,
          tooltip: 'Minimize',
          onPressed: () async {
            await windowManager.minimize();
          },
          isDark: isDark,
        ),
        _buildControlButton(
          icon: _isMaximized ? Icons.crop_square : Icons.crop_din,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          isDark: isDark,
        ),
        _buildControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          onPressed: () async {
            await windowManager.close();
          },
          isCloseButton: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isCloseButton = false,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        hoverColor:
            isCloseButton
                ? Colors.red
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1)),
        child: Container(
          width: 46,
          height: 36,
          color: Colors.transparent,
          child: Center(
            child: Icon(
              icon, 
              size: 16, 
              color: isCloseButton ? 
                (isDark ? Colors.white : Colors.red.shade700) : 
                (isDark ? Colors.white : Colors.black87)
            )
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandles() {
    if (_isMaximized) return const SizedBox.shrink();

    return SizedBox(
      height: 5,
      child: Row(
        children: [
          GestureDetector(
            onPanStart:
                (details) => windowManager.startResizing(ResizeEdge.bottomLeft),
            child: Container(
              width: 10,
              height: 10,
              color: Colors.transparent,
              margin: const EdgeInsets.only(left: 5),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanStart:
                  (details) => windowManager.startResizing(ResizeEdge.bottom),
              child: Container(color: Colors.transparent),
            ),
          ),
          GestureDetector(
            onPanStart:
                (details) =>
                    windowManager.startResizing(ResizeEdge.bottomRight),
            child: Container(
              width: 10,
              height: 10,
              color: Colors.transparent,
              margin: const EdgeInsets.only(right: 5),
            ),
          ),
        ],
      ),
    );
  }
}
