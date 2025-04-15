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
    
    // Navigate to the app viewer screen with a pop-in animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppViewerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.8;
          const end = 1.0;
          const curve = Curves.easeOutQuint;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var scaleAnimation = animation.drive(tween);
          
          var opacityTween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          var opacityAnimation = animation.drive(opacityTween);
          
          return ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
} 