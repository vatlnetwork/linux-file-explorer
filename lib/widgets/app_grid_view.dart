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

class _AppGridViewState extends State<AppGridView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              return _buildAppItem(app, fixedIconSize, isDarkMode);
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
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _launchApp(app),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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
                      ? Colors.grey.shade700 
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: SystemIcon(
                  app: app,
                  size: actualIconSize,
                  fallbackColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
              ),
              
              const SizedBox(height: 8),
              
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