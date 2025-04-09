import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import '../utils/color_extensions.dart' show ColorExtensions;
import '../models/bookmark_item.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import 'disk_usage_widget.dart';
import 'mounted_usb_drives_widget.dart';

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
          width: 220,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF252525)
                : const Color(0xFFF5F5F5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
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

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        // Clear focused bookmark when header is tapped
        setState(() {
          _focusedBookmarkPath = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF252525) 
              : const Color(0xFFF5F5F5),
          border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                  ? Colors.black 
                  : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.folder,
              color: isDarkMode 
                  ? Colors.blue.shade300 
                  : Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Linux File Explorer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDarkMode 
                      ? Colors.grey.shade200 
                      : Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.info_outline, 
                size: 18,
                color: isDarkMode 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade600,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(const Size(24, 24)),
              tooltip: 'Drag to reorder bookmarks',
              onPressed: () {
                NotificationService.showNotification(
                  context,
                  message: 'Drag bookmarks to reorder them',
                  type: NotificationType.info,
                );
              },
            ),
          ],
        ),
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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 4, right: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: isDarkMode
              ? const Color(0xFF303030)
              : Colors.grey.shade100,
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
              padding: const EdgeInsets.symmetric(vertical: 4),
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
                    final double elevation = lerpDouble(0, 8, animValue)!;
                    return Material(
                      elevation: elevation,
                      color: isDarkMode
                          ? const Color(0xFF333333)
                          : Colors.blue.shade50,
                      shadowColor: Colors.blue.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderableBookmarkTile(BuildContext context, BookmarkItem bookmark, bool isSelected, int index, bool isRecentlyReordered) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isFocused = _focusedBookmarkPath == bookmark.path;
    
    // Animation for the highlight effect
    final Animation<Color?> highlightAnimation = ColorTween(
      begin: isDarkMode ? Colors.blue.shade800.withValues(alpha: 0.4) : Colors.blue.shade100,
      end: isSelected 
          ? (isDarkMode ? Colors.blueGrey.shade700.withValues(alpha: 0.5) : Colors.blue.shade100)
          : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    return Padding(
      key: ValueKey(bookmark.path),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: isRecentlyReordered 
                ? highlightAnimation.value
                : (isSelected 
                    ? (isDarkMode ? Colors.blueGrey.shade700.withValues(alpha: 0.5) : Colors.blue.shade100)
                    : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white)),
            borderRadius: BorderRadius.circular(4),
            border: isFocused ? Border.all(
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade500,
              width: 2.0,
            ) : Border.all(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade700.withValues(alpha: 0.5) : Colors.blue.shade400.withValues(alpha: 0.5))
                    : isRecentlyReordered
                        ? (isDarkMode ? Colors.blue.shade700.withValues(alpha: 0.5) : Colors.blue.shade300.withValues(alpha: 0.5))
                        : (isDarkMode ? Colors.black.withValues(alpha: 0.4) : Colors.grey.shade300.withValues(alpha: 0.5)),
                spreadRadius: isSelected ? 1 : 0,
                blurRadius: isSelected ? 3 : (isRecentlyReordered ? 4 : 2),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              // Set focus first and cancel any pending unfocus operations
              setState(() {
                _focusedBookmarkPath = bookmark.path;
              });
              // Navigate to the bookmark path
              widget.onNavigate(bookmark.path);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bookmark.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected || isRecentlyReordered ? FontWeight.bold : FontWeight.normal,
                        color: isDarkMode
                            ? Colors.grey.shade200
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Icon(
                        Icons.drag_handle,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper for proxy decorator
  static double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
} 