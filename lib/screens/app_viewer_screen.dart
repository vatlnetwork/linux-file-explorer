import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_service.dart';
import '../widgets/app_grid_view.dart';
import 'package:window_manager/window_manager.dart';

class AppViewerScreen extends StatefulWidget {
  const AppViewerScreen({super.key});

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
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
    return Scaffold(
      body: Column(
        children: [
          // Title bar
          _buildTitleBar(context),
          
          // Main content
          Expanded(
            child: const AppGridView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? const Color(0xFF303030) 
        : const Color(0xFFBBDEFB);
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Icon and Title
          Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                Icons.apps,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Applications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Applications',
            onPressed: () {
              // Find the AppService and refresh the applications
              Provider.of<AppService>(context, listen: false).refreshApps();
            },
          ),
          
          // Window controls
          IconButton(
            icon: Icon(_isMaximized ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            onPressed: () {
              if (_isMaximized) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
} 