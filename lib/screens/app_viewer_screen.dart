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

class _AppViewerScreenState extends State<AppViewerScreen> with WindowListener, TickerProviderStateMixin {
  bool _isMaximized = false;
  late AnimationController _titleBarAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _titleBarOpacity;
  late Animation<Offset> _titleBarSlide;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindowState();
    _initAnimations();
  }
  
  void _initAnimations() {
    // Title bar animation controller
    _titleBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // Content animation controller with delay
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Title bar animations
    _titleBarOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleBarAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _titleBarSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleBarAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    
    // Content animations
    _contentOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
    ));
    
    // Start animations with a slight delay between them
    Future.delayed(const Duration(milliseconds: 50), () {
      _titleBarAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 150), () {
        _contentAnimationController.forward();
      });
    });
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void dispose() {
    _titleBarAnimationController.dispose();
    _contentAnimationController.dispose();
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
          // Title bar with animation
          FadeTransition(
            opacity: _titleBarOpacity,
            child: SlideTransition(
              position: _titleBarSlide,
              child: _buildTitleBar(context),
            ),
          ),
          
          // Main content with animation
          Expanded(
            child: FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentSlide,
                child: const AppGridView(),
              ),
            ),
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