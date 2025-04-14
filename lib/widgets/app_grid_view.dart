import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_item.dart';
import '../services/app_service.dart';
import '../services/icon_size_service.dart';
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
    final iconSizeService = Provider.of<IconSizeService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final double iconSize = iconSizeService.gridIconSize;
    final double uiScale = iconSizeService.gridUIScale;
    
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
    
    // Calculate the number of items per row based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine optimal items per row based on available width
        // We want each item to be around 100-150 pixels wide
        final double targetItemWidth = 130.0 * uiScale;
        final int crossAxisCount = constraints.maxWidth ~/ targetItemWidth;
        
        // Grid padding that scales with UI scale but has a reasonable minimum
        final gridPadding = EdgeInsets.all((8 * uiScale).clamp(6, 16));
        
        return RefreshIndicator(
          onRefresh: () => appService.refreshApps(),
          child: GridView.builder(
            padding: gridPadding,
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount.clamp(1, 8), // Min 1, max 8 icons per row
              childAspectRatio: 0.8, // Slightly taller than wide for labels
              crossAxisSpacing: 8 * uiScale,
              mainAxisSpacing: 8 * uiScale,
            ),
            itemCount: appService.apps.length,
            itemBuilder: (context, index) {
              final app = appService.apps[index];
              return _buildAppItem(app, iconSize, isDarkMode);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAppItem(AppItem app, double iconSize, bool isDarkMode) {
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
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? Colors.grey.shade700 
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: SystemIcon(
                  app: app,
                  size: iconSize * 0.9,
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
                  fontSize: 13,
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