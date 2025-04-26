import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_item.dart';
import '../services/app_service.dart';
import 'system_icon.dart';

class AppGridView extends StatefulWidget {
  const AppGridView({super.key});

  @override
  State<AppGridView> createState() => _AppGridViewState();
}

class _AppGridViewState extends State<AppGridView> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _staggeredAnimationController;

  @override
  void initState() {
    super.initState();
    _staggeredAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Delay slightly to coordinate with parent animations
    Future.delayed(const Duration(milliseconds: 200), () {
      _staggeredAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _staggeredAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Create a staggered animation for a specific item index
  Animation<double> _createStaggeredAnimation(int index, int total) {
    // Calculate a staggered start time based on index 
    // We want animations to cascade, so each item starts a bit after the previous one
    final startInterval = 0.05 * (index % 12); // Group by rows of 12 for better performance
    final endInterval = startInterval + 0.4; // Each animation lasts 40% of the total duration
    
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggeredAnimationController,
        curve: Interval(
          startInterval.clamp(0.0, 0.6), // Don't start too late
          endInterval.clamp(0.2, 1.0), // Ensure animations complete
          curve: Curves.easeOutQuint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Use a fixed small icon size instead of the one from iconSizeService
    final double fixedIconSize = 36.0;
    
    // If apps are loading and we don't have cached data
    if (appService.isLoading && appService.apps.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // If no apps found
    if (appService.apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps,
              size: 64,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'No applications found',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    // Fixed item size for the grid (keeps icons the same size regardless of window size)
    final double fixedItemWidth = 120.0;
    final double fixedItemHeight = fixedItemWidth * 1.25; // Slightly taller than wide for labels
    
    // Calculate the number of items per row based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many items can fit in a row based on the fixed item size
        final int crossAxisCount = (constraints.maxWidth / fixedItemWidth).floor().clamp(1, 12);
        
        // Consistent padding regardless of window size
        final gridPadding = const EdgeInsets.all(12.0);
        
        return RefreshIndicator(
          onRefresh: () => appService.refreshApps(),
          child: GridView.builder(
            padding: gridPadding,
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: fixedItemWidth / fixedItemHeight,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: appService.apps.length,
            itemBuilder: (context, index) {
              final app = appService.apps[index];
              // Create staggered animation for this specific item
              final animation = _createStaggeredAnimation(index, appService.apps.length);
              
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: animation.value,
                    child: Opacity(
                      opacity: animation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildAppItem(app, fixedIconSize, isDarkMode),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAppItem(AppItem app, double iconSize, bool isDarkMode) {
    // Fixed size values for consistent appearance regardless of window size
    const double iconContainerSize = 48.0;
    const double actualIconSize = 32.0;
    const double fontSize = 12.0;
    
    return Card(
      elevation: 2,
      color: isDarkMode ? const Color(0xFF2D2E30) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchApp(app),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon - use SystemIcon instead of default icon
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF3C4043)
                      : const Color(0xFFF1F3F4),
                  shape: BoxShape.circle,
                ),
                child: SystemIcon(
                  app: app,
                  size: actualIconSize,
                  fallbackColor: isDarkMode ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // App name
              Text(
                app.name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _launchApp(AppItem app) async {
    final appService = Provider.of<AppService>(context, listen: false);
    final success = await appService.launchApp(app);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch ${app.name}')),
      );
    }
  }
} 