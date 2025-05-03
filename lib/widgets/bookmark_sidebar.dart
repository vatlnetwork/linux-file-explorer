import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../utils/color_extensions.dart' show ColorExtensions;
import '../models/bookmark_item.dart';
import '../models/file_item.dart';
import '../services/bookmark_service.dart';
import 'disk_usage_widget.dart';
import 'mounted_usb_drives_widget.dart';
import 'apps_bookmark_button.dart';
import 'folder_drop_target.dart';

class BookmarkSidebar extends StatefulWidget {
  final Function(String) onNavigate;
  final String currentPath;
  final GlobalKey<BookmarkSidebarState>? bookmarkKey;
  
  const BookmarkSidebar({
    super.key,
    required this.onNavigate,
    required this.currentPath,
    this.bookmarkKey,
  });

  void clearFocus() {
    bookmarkKey?.currentState?.clearFocusedBookmark();
  }

  @override
  State<BookmarkSidebar> createState() => BookmarkSidebarState();
}

class BookmarkSidebarState extends State<BookmarkSidebar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _lastReorderedIndex;
  String? _focusedBookmarkPath;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method to clear focused bookmark, can be called from parent
  void clearFocusedBookmark() {
    if (_focusedBookmarkPath != null) {
      setState(() {
        _focusedBookmarkPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookmarkService>(
      builder: (context, bookmarkService, child) {
        final bookmarks = bookmarkService.bookmarks;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          width: 200,
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF252525) // Dark mode background
                : Colors.white, // White background
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.black : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: const AppsBookmarkButton(),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 8,
                endIndent: 8,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              Expanded(
                child: _buildBookmarksList(context, bookmarks, bookmarkService),
              ),
              MountedUsbDrivesWidget(onNavigate: widget.onNavigate),
              DiskUsageWidget(path: widget.currentPath),
            ],
          ),
        );
      },
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: isDarkMode
            ? const Color(0xFF404040) // Gray for drag and drop background
            : const Color(0xFFE0E0E0), // Light gray for drag and drop background
      ),
      child: NotificationListener<ScrollNotification>(
        // Detect scroll interactions which usually mean user is interacting
        // with the list background
        onNotification: (notification) {
          // Clear focus when user scrolls the list
          if (notification is ScrollUpdateNotification) {
            setState(() {
              _focusedBookmarkPath = null;
            });
          }
          return false;
        },
        child: Listener(
          // Detect tap-up events that might reach the list background
          onPointerUp: (_) {
            // Use a small delay to allow tap events to complete on items first
            Future.delayed(Duration.zero, () {
              // If hit test succeeds for an actual bookmark item, this will be
              // overridden by the item's tap handler
              setState(() {
                _focusedBookmarkPath = null;
              });
            });
          },
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(0, 10, animValue)!;
                  return Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    shadowColor: isDarkMode ? Colors.blue.shade700.withValues(alpha: 0.4) : Colors.blue.shade300.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF4A4A4A) // Lighter gray for drag proxy
                            : const Color(0xFFE8F1FF), // Very light blue-gray for drag proxy
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                              ? Colors.blue.shade900.withValues(alpha: 0.3) 
                              : Colors.blue.shade200.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableBookmarkTile(
    BuildContext context,
    BookmarkItem bookmark,
    bool isSelected,
    int index,
    bool isRecentlyReordered,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _focusedBookmarkPath == bookmark.path;
    
    Widget bookmarkTile = ReorderableDragStartListener(
      key: ValueKey('${bookmark.path}_drag_listener'),
      index: index,
      child: Material(
        key: ValueKey('${bookmark.path}_material'),
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('${bookmark.path}_inkwell'),
          onTap: () {
            widget.onNavigate(bookmark.path);
          },
          onTapDown: (_) {
            setState(() {
              _focusedBookmarkPath = bookmark.path;
            });
          },
          child: Container(
            key: ValueKey('${bookmark.path}_container'),
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100)
                  : (isFocused
                      ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              key: ValueKey('${bookmark.path}_row'),
              children: [
                Icon(
                  Icons.folder,
                  key: ValueKey('${bookmark.path}_icon'),
                  size: 16,
                  color: isSelected
                      ? (isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700)
                      : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  key: ValueKey('${bookmark.path}_expanded'),
                  child: Text(
                    key: ValueKey('${bookmark.path}_text'),
                    bookmark.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? (isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700)
                          : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with FolderDropTarget to enable dropping files
    return FolderDropTarget(
      key: ValueKey('${bookmark.path}_drop_target'),
      folder: FileItem(
        name: bookmark.name,
        path: bookmark.path,
        type: FileItemType.directory,
        modifiedTime: DateTime.now(),
        size: 0,
      ),
      onNavigateToDirectory: widget.onNavigate,
      onDropSuccessful: () {
        // No need to refresh since this is a bookmark
      },
      child: bookmarkTile,
    );
  }
  
  // Helper for proxy decorator
  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
} 