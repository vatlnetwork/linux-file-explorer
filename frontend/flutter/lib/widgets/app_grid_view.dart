import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_item.dart';
import '../services/app_service.dart';
import 'system_icon.dart';

class AppGridView extends StatefulWidget {
  final String searchQuery;
  final String selectedCategory;

  const AppGridView({
    super.key,
    this.searchQuery = '',
    this.selectedCategory = 'All',
  });

  @override
  State<AppGridView> createState() => _AppGridViewState();
}

class _AppGridViewState extends State<AppGridView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Animation<double> _createStaggeredAnimation(int index, int total) {
    final double start = index / total;
    final double end = start + 0.2;
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut),
      ),
    );
  }

  // Helper method to determine app category
  String _getAppCategory(AppItem app) {
    final name = app.name.toLowerCase();
    final path = app.path.toLowerCase();
    final desktop = app.desktopFile.toLowerCase();

    if (path.contains('system') || desktop.contains('system')) return 'System';
    if (path.contains('internet') ||
        name.contains('browser') ||
        name.contains('web')) {
      return 'Internet';
    }
    if (path.contains('dev') ||
        name.contains('code') ||
        name.contains('editor')) {
      return 'Development';
    }
    if (path.contains('graphics') ||
        name.contains('image') ||
        name.contains('photo')) {
      return 'Graphics';
    }
    if (path.contains('office') ||
        name.contains('doc') ||
        name.contains('calc')) {
      return 'Office';
    }
    if (path.contains('game') || desktop.contains('game')) return 'Games';
    return 'Other';
  }

  // Filter apps based on search query and category
  List<AppItem> _filterApps(List<AppItem> apps) {
    return apps.where((app) {
      // Apply search filter
      final searchMatch =
          widget.searchQuery.isEmpty ||
          app.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          app.path.toLowerCase().contains(widget.searchQuery.toLowerCase());

      // Apply category filter
      final categoryMatch =
          widget.selectedCategory == 'All' ||
          _getAppCategory(app) == widget.selectedCategory;

      return searchMatch && categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Fixed item size for the grid
    const double fixedItemWidth = 120.0;
    const double fixedItemHeight =
        fixedItemWidth * 1.4; // Increased height ratio for better text fit

    // Filter the apps
    final filteredApps = _filterApps(appService.apps);

    // If apps are loading and we don't have cached data
    if (appService.isLoading && appService.apps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // If no apps found after filtering
    if (filteredApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.apps_outlined,
              size: 64,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              widget.searchQuery.isNotEmpty
                  ? 'No applications found matching "${widget.searchQuery}"'
                  : 'No applications found in category "${widget.selectedCategory}"',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Calculate the number of items per row based on available width
    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = (constraints.maxWidth / fixedItemWidth)
            .floor()
            .clamp(1, 12);

        return RefreshIndicator(
          onRefresh: () => appService.refreshApps(),
          child: GridView.builder(
            padding: const EdgeInsets.all(12.0),
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: fixedItemWidth / fixedItemHeight,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              final animation = _createStaggeredAnimation(
                index,
                filteredApps.length,
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: animation.value,
                    child: Opacity(opacity: animation.value, child: child),
                  );
                },
                child: _buildAppItem(app, 36.0, isDarkMode),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppItem(AppItem app, double iconSize, bool isDarkMode) {
    // Fixed size values for consistent appearance
    const double iconContainerSize = 56.0;
    const double actualIconSize = 36.0;
    const double fontSize = 13.0;

    return Card(
      elevation: 0,
      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _launchApp(app),
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDarkMode ? const Color(0xFF3C4043) : Colors.grey.shade100,
        splashColor:
            isDarkMode ? const Color(0xFF4C5054) : Colors.grey.shade200,
        highlightColor:
            isDarkMode ? const Color(0xFF4C5054) : Colors.grey.shade200,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // App icon with gradient background
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDarkMode
                            ? [Color(0xFF3C4043), Color(0xFF202124)]
                            : [Color(0xFFE8F0FE), Color(0xFFE3E8F4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDarkMode
                              ? Colors.black.withAlpha((0.2 * 255).round())
                              : Colors.grey.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SystemIcon(
                    app: app,
                    size: actualIconSize,
                    fallbackColor:
                        isDarkMode
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // App name with improved typography
              Flexible(
                child: Text(
                  app.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color:
                        isDarkMode
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                    height: 1.2,
                  ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to launch ${app.name}')));
    }
  }
}
