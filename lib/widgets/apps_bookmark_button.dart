import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_service.dart';
import '../screens/app_viewer_screen.dart';

class AppsBookmarkButton extends StatelessWidget {
  const AppsBookmarkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _openAppViewer(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF424242) 
              : const Color(0xFFFFCC80), // Light orange
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              Icons.apps,
              size: 20,
              color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800,
            ),
            const SizedBox(width: 6),
            Text(
              'Apps',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openAppViewer(BuildContext context) {
    // Initialize the app service if it hasn't been initialized yet
    final appService = Provider.of<AppService>(context, listen: false);
    appService.init();
    
    // Navigate to the app viewer screen with an enhanced pop-in animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppViewerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use a spring curve for a more natural, bouncy feel
          const scaleCurve = Interval(0.0, 0.8, curve: Curves.easeOutCubic);
          const opacityCurve = Interval(0.0, 0.6, curve: Curves.easeOut);
          const slideCurve = Interval(0.0, 0.7, curve: Curves.easeOutCubic);
          
          // Scale animation - starts smaller and bounces slightly past the target
          var scaleTween = Tween(begin: 0.6, end: 1.0).chain(CurveTween(curve: scaleCurve));
          var scaleAnimation = animation.drive(scaleTween);
          
          // Opacity animation - fades in quickly
          var opacityTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: opacityCurve));
          var opacityAnimation = animation.drive(opacityTween);
          
          // Slide up animation - slight upward movement
          var slideTween = Tween(begin: const Offset(0, 0.2), end: Offset.zero).chain(CurveTween(curve: slideCurve));
          var slideAnimation = animation.drive(slideTween);
          
          return SlideTransition(
            position: slideAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(
                opacity: opacityAnimation,
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
} 