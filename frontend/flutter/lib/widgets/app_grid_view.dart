import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
  bool _isDragging = false;

  final List<String> _categories = [
    'System',
    'Internet',
    'Development',
    'Graphics',
    'Media',
    'Office',
    'Games',
    'Other',
  ];

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

  // Filter apps based on search query and category
  List<AppItem> _filterApps(List<AppItem> apps, AppService appService) {
    return apps.where((app) {
      // Apply search filter
      final searchMatch =
          widget.searchQuery.isEmpty ||
          app.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          app.path.toLowerCase().contains(widget.searchQuery.toLowerCase());

      // Apply category filter
      final categoryMatch =
          widget.selectedCategory == 'All' ||
          appService.getAppCategory(app) == widget.selectedCategory;

      return searchMatch && categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Fixed item size for the grid
    const double fixedItemWidth = 120.0;
    const double fixedItemHeight = fixedItemWidth * 1.4;

    // Filter the apps
    final filteredApps = _filterApps(appService.apps, appService);

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

        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => appService.refreshApps(),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
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
                              child: Opacity(
                                opacity: animation.value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildDraggableAppItem(
                            app,
                            36.0,
                            isDarkMode,
                            appService,
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isDragging)
                    Container(
                      color:
                          isDarkMode
                              ? Colors.black.withAlpha(179)
                              : Colors.white.withAlpha(179),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            padding: const EdgeInsets.all(24),
                            children:
                                _categories
                                    .map(
                                      (category) => _buildCategoryDropTarget(
                                        category,
                                        isDarkMode,
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableAppItem(
    AppItem app,
    double iconSize,
    bool isDarkMode,
    AppService appService,
  ) {
    return Draggable<AppItem>(
      data: app,
      onDragStarted: () => setState(() => _isDragging = true),
      onDragEnd: (_) => setState(() => _isDragging = false),
      onDraggableCanceled: (_, __) => setState(() => _isDragging = false),
      feedback: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          height: 120 * 1.4,
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? Colors.white.withValues(
                      red: 255,
                      green: 255,
                      blue: 255,
                      alpha: 25,
                    )
                    : Colors.white.withValues(
                      red: 255,
                      green: 255,
                      blue: 255,
                      alpha: 51,
                    ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDarkMode
                      ? Colors.white.withValues(
                        red: 255,
                        green: 255,
                        blue: 255,
                        alpha: 51,
                      )
                      : Colors.black.withValues(
                        red: 0,
                        green: 0,
                        blue: 0,
                        alpha: 26,
                      ),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? Colors.black.withValues(
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 51,
                        )
                        : Colors.black.withValues(
                          red: 0,
                          green: 0,
                          blue: 0,
                          alpha: 25,
                        ),
                blurRadius: 8,
                spreadRadius: -2,
              ),
            ],
          ),
          child: _buildAppItem(app, iconSize, isDarkMode),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildAppItem(app, iconSize, isDarkMode),
      ),
      child: _buildAppItem(app, iconSize, isDarkMode),
    );
  }

  Widget _buildAppItem(AppItem app, double iconSize, bool isDarkMode) {
    // Fixed size values for consistent appearance
    const double iconContainerSize = 56.0;
    const double actualIconSize = 36.0;
    const double fontSize = 13.0;

    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(details.globalPosition, app);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withValues(
                        red: 0,
                        green: 0,
                        blue: 0,
                        alpha: 51,
                      )
                      : Colors.black.withValues(
                        red: 0,
                        green: 0,
                        blue: 0,
                        alpha: 25,
                      ),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: InkWell(
          onTap: () => _launchApp(app),
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
          splashColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? const Color(0xFF3C4043)
                            : const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withValues(
                                  red: 0,
                                  green: 0,
                                  blue: 0,
                                  alpha: 51,
                                )
                                : Colors.black.withValues(
                                  red: 0,
                                  green: 0,
                                  blue: 0,
                                  alpha: 25,
                                ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SystemIcon(
                    app: app,
                    size: actualIconSize,
                    fallbackColor:
                        isDarkMode
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  app.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(Offset position, AppItem app) {
    final appService = Provider.of<AppService>(context, listen: false);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.refresh, size: 18),
              SizedBox(width: 8),
              Text('Reset Category'),
            ],
          ),
          onTap: () {
            appService.resetAppCategory(app);
          },
        ),
      ],
    );
  }

  void _launchApp(AppItem app) async {
    final appService = Provider.of<AppService>(context, listen: false);
    await appService.launchApp(app);
  }

  Widget _buildCategoryDropTarget(String category, bool isDarkMode) {
    return DragTarget<AppItem>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final appService = Provider.of<AppService>(context, listen: false);
        appService.setAppCategory(details.data, category);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color:
                candidateData.isNotEmpty
                    ? Theme.of(context).primaryColor.withAlpha(26)
                    : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
                        .withAlpha(128),
            border: Border.all(
              color:
                  candidateData.isNotEmpty
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              category,
              style: TextStyle(
                color:
                    candidateData.isNotEmpty
                        ? Theme.of(context).primaryColor
                        : (isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade700),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
