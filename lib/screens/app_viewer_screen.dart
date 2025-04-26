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

  @override
  void dispose() {
    _titleBarAnimationController.dispose();
    _contentAnimationController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }
  
  @override
  void onWindowMaximize() {
    // No longer needed
  }

  @override
  void onWindowUnmaximize() {
    // No longer needed
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
        ? const Color(0xFF202124)
        : Colors.white;
    
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26),
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
                Icon(
                  Icons.apps,
                  color: isDarkMode ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Applications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
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
                Provider.of<AppService>(context, listen: false).refreshApps();
              },
            ),
            
            // Window controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.minimize),
                  tooltip: 'Minimize',
                  onPressed: () => windowManager.minimize(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 