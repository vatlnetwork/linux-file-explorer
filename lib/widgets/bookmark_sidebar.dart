import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bookmark_item.dart';
import '../services/bookmark_service.dart';

class BookmarkSidebar extends StatefulWidget {
  final Function(String) onNavigate;
  final String currentPath;
  
  const BookmarkSidebar({
    super.key,
    required this.onNavigate,
    required this.currentPath,
  });

  @override
  State<BookmarkSidebar> createState() => _BookmarkSidebarState();
}

class _BookmarkSidebarState extends State<BookmarkSidebar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _lastReorderedIndex;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkService>(
      builder: (context, bookmarkService, child) {
        final bookmarks = bookmarkService.bookmarks;
        
        return Container(
          width: 220,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF252525)
              : const Color(0xFFF5F5F5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: _buildBookmarksList(context, bookmarks, bookmarkService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF333333) 
            : const Color(0xFFE0E0E0),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black54
                : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark),
          const SizedBox(width: 8),
          const Text(
            'Bookmarks',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(const Size(24, 24)),
            tooltip: 'Drag to reorder bookmarks',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Drag bookmarks to reorder them'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(BuildContext context, List<BookmarkItem> bookmarks, BookmarkService bookmarkService) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No bookmarks yet',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Right-click on a folder and select "Add to Bookmarks"',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade500
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        // Add a highlight color for the drag target
        canvasColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF303030)
            : Colors.grey.shade100,
      ),
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: bookmarks.length,
        onReorder: (oldIndex, newIndex) async {
          await bookmarkService.reorderBookmarks(oldIndex, newIndex);
          
          // Store the new index for highlighting
          setState(() {
            _lastReorderedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
          });
          
          // Reset animation controller and start animation
          _animationController.reset();
          _animationController.forward().then((_) {
            // Clear the highlight after animation completes
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _lastReorderedIndex = null;
                });
              }
            });
          });
        },
        itemBuilder: (context, index) {
          final bookmark = bookmarks[index];
          final isSelected = widget.currentPath == bookmark.path;
          final isRecentlyReordered = _lastReorderedIndex == index;
          
          return _buildReorderableBookmarkTile(
            context, 
            bookmark, 
            isSelected, 
            index,
            isRecentlyReordered,
          );
        },
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF333333)
                    : Colors.blue.shade50,
                shadowColor: Colors.blue.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildReorderableBookmarkTile(BuildContext context, BookmarkItem bookmark, bool isSelected, int index, bool isRecentlyReordered) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Animation for the highlight effect
    final Animation<Color?> highlightAnimation = ColorTween(
      begin: isDarkMode ? Colors.blue.shade800.withOpacity(0.4) : Colors.blue.shade100,
      end: isSelected 
          ? (isDarkMode ? Colors.blueGrey.shade800.withOpacity(0.3) : Colors.blue.shade50)
          : (isDarkMode ? const Color(0xFF252525) : Colors.white),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    return Container(
      key: ValueKey(bookmark.path),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: isRecentlyReordered 
            ? highlightAnimation.value
            : (isSelected 
                ? (isDarkMode ? Colors.blueGrey.shade800.withOpacity(0.3) : Colors.blue.shade50)
                : (isDarkMode ? const Color(0xFF252525) : Colors.white)),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isRecentlyReordered
              ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300)
              : (isDarkMode ? Colors.black45 : Colors.grey.shade200),
          width: isRecentlyReordered ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showBookmarkContextMenu(context, bookmark, details.globalPosition);
        },
        child: ListTile(
          leading: const Icon(Icons.folder, color: Colors.amber),
          title: Text(
            bookmark.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected || isRecentlyReordered ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: () => widget.onNavigate(bookmark.path),
          trailing: ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(
                Icons.drag_handle,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookmarkContextMenu(BuildContext context, BookmarkItem bookmark, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove bookmark', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    if (result == 'remove') {
      final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
      bookmarkService.removeBookmark(bookmark.path);
    }
  }
  
  // Helper for proxy decorator
  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
} 