import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_service.dart';
import '../models/app_item.dart';
import '../widgets/system_icon.dart';

class AppViewerScreen extends StatefulWidget {
  const AppViewerScreen({super.key});

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSection = 'Discover';
  bool _isEditingSections = false;

  @override
  Widget build(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      body: Column(
        children: [
          // Top bar with search
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to File Explorer',
                ),
                const SizedBox(width: 8),
                const Text(
                  'Applications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? const Color(0xFF3D3D3D)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged:
                          (value) => setState(() => _searchQuery = value),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Search applications...',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Sidebar
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[100],
                    border: Border(
                      right: BorderSide(
                        color:
                            isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            // Sections header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'SECTIONS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (!_isEditingSections)
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 14),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => _isEditingSections = true,
                                          ),
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[700],
                                    ),
                                ],
                              ),
                            ),
                            // All sections
                            ...appService.allSections.map(
                              (section) => _buildSidebarItem(
                                section,
                                icon: _getSectionIcon(section),
                                isSelected: _selectedSection == section,
                                showDeleteButton:
                                    _isEditingSections &&
                                    !appService.isDefaultSection(section),
                                onDelete: () => _deleteSection(section),
                              ),
                            ),
                            if (_isEditingSections)
                              _buildSidebarItem(
                                'Add New Section',
                                icon: Icons.add,
                                onTap: _addNewSection,
                              ),
                          ],
                        ),
                      ),
                      if (_isEditingSections)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed:
                                () =>
                                    setState(() => _isEditingSections = false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: const Size(0, 24),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Main content
                Expanded(child: _buildMainContent(appService, isDarkMode)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewSection() {
    final appService = Provider.of<AppService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Section'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter section name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  await appService.addSection(name);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSection(String section) async {
    final appService = Provider.of<AppService>(context, listen: false);
    await appService.deleteSection(section);
    if (_selectedSection == section) {
      setState(() => _selectedSection = 'Discover');
    }
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'Discover':
        return Icons.explore;
      case 'Create':
        return Icons.create;
      case 'Work':
        return Icons.work;
      case 'Play':
        return Icons.games;
      case 'Develop':
        return Icons.code;
      case 'Categories':
        return Icons.category;
      default:
        return Icons.folder;
    }
  }

  Widget _buildSidebarItem(
    String title, {
    IconData? icon,
    bool isSelected = false,
    bool showDeleteButton = false,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<AppItem>(
      onWillAccept: (data) => data != null,
      onAccept: (app) {
        final appService = Provider.of<AppService>(context, listen: false);
        appService.addAppToSection(title, app);
      },
      builder: (context, candidateData, rejectedData) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => setState(() => _selectedSection = title),
            child: Container(
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200]
                        : candidateData.isNotEmpty
                        ? isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[300]
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 14,
                      color:
                          isSelected
                              ? isDarkMode
                                  ? Colors.white
                                  : Colors.black
                              : isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected
                                ? isDarkMode
                                    ? Colors.white
                                    : Colors.black
                                : isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700],
                      ),
                    ),
                  ),
                  if (showDeleteButton)
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: onDelete,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(AppService appService, bool isDarkMode) {
    if (appService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredApps = _getFilteredApps(appService);

    if (filteredApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.apps_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No applications found matching "${_searchQuery}"'
                  : 'No applications in this section',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final int crossAxisCount = (screenWidth / 200).floor().clamp(2, 6);
        final double iconSize = (screenWidth / crossAxisCount) * 0.3;

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: filteredApps.length,
          itemBuilder: (context, index) {
            final app = filteredApps[index];
            return _buildAppCard(app, isDarkMode, iconSize);
          },
        );
      },
    );
  }

  List<AppItem> _getFilteredApps(AppService appService) {
    final List<AppItem> sectionApps = appService.getAppsInSection(
      _selectedSection,
    );

    if (_searchQuery.isEmpty) {
      return sectionApps;
    }

    return sectionApps.where((app) {
      return app.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildAppCard(AppItem app, bool isDarkMode, double iconSize) {
    return Draggable<AppItem>(
      data: app,
      feedback: Material(
        elevation: 4,
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SystemIcon(
                app: app,
                size: 48,
                fallbackColor:
                    isDarkMode ? Colors.blue[300]! : Colors.blue[700]!,
              ),
              const SizedBox(height: 8),
              Text(
                app.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
          ),
        ),
        child: InkWell(
          onTap: () {
            final appService = Provider.of<AppService>(context, listen: false);
            appService.launchApp(app);
          },
          onSecondaryTapUp: (details) {
            _showAppContextMenu(context, app, details.globalPosition);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color:
                        isDarkMode ? const Color(0xFF3D3D3D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SystemIcon(
                    app: app,
                    size: iconSize * 0.75,
                    fallbackColor:
                        isDarkMode ? Colors.blue[300]! : Colors.blue[700]!,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  app.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      app.isSystemApp ? Icons.settings : Icons.apps,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      app.isSystemApp ? 'System' : 'Application',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppContextMenu(BuildContext context, AppItem app, Offset position) {
    final appService = Provider.of<AppService>(context, listen: false);
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'launch',
          child: Row(
            children: const [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 8),
              Text('Launch'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...appService.allSections
            .where((section) => section != 'Discover')
            .map(
              (section) => PopupMenuItem<String>(
                value: 'section:$section',
                child: Row(
                  children: [
                    Icon(
                      appService.getAppsInSection(section).contains(app)
                          ? Icons.remove_circle_outline
                          : Icons.add_circle_outline,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(section),
                  ],
                ),
              ),
            ),
      ],
    ).then((value) {
      if (value == null) return;

      if (value == 'launch') {
        appService.launchApp(app);
      } else if (value.startsWith('section:')) {
        final section = value.substring(8);
        if (appService.getAppsInSection(section).contains(app)) {
          appService.removeAppFromSection(section, app);
        } else {
          appService.addAppToSection(section, app);
        }
        setState(() {});
      }
    });
  }
}
