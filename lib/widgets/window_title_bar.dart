import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
// ignore: unused_import
import '../utils/color_extensions.dart';

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
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(child: widget.child),
            _buildResizeHandles(),
          ],
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
