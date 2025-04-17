import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/icon_size_service.dart';
import 'gallery_item_widget.dart';

/// A widget that displays files in a gallery view with large previews
/// Similar to the macOS Finder's gallery view
class GalleryViewWidget extends StatefulWidget {
  final List<FileItem> items;
  final Function(FileItem, bool) onItemTap;
  final Function(FileItem) onItemDoubleTap;
  final Function(FileItem) onItemLongPress;
  final Function(FileItem, Offset) onItemRightClick;
  final Set<String> selectedItemsPaths;
  final Function() onEmptyAreaTap;
  final Function(Offset) onEmptyAreaRightClick;
  
  const GalleryViewWidget({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onItemDoubleTap,
    required this.onItemLongPress,
    required this.onItemRightClick,
    required this.selectedItemsPaths,
    required this.onEmptyAreaTap,
    required this.onEmptyAreaRightClick,
  });
  
  @override
  State<GalleryViewWidget> createState() => _GalleryViewWidgetState();
}

class _GalleryViewWidgetState extends State<GalleryViewWidget> with AutomaticKeepAliveClientMixin {
  // Currently selected index for large preview
  int _selectedIndex = 0;
  
  // Scroll controller for the thumbnail scrubber
  final ScrollController _scrubberController = ScrollController();
  final PageController _pageController = PageController();
  
  // File items filtered by type
  late List<FileItem> _imageItems;
  late List<FileItem> _documentItems;
  late List<FileItem> _otherItems;
  late List<FileItem> _directoryItems;
  
  // Flag to track initialization and prevent memory leaks
  bool _isDisposed = false;
  
  @override
  bool get wantKeepAlive => false; // Don't keep widget alive when not visible
  
  @override
  void initState() {
    super.initState();
    _filterItems();
    
    // If a selected item exists, scroll to it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _scrollToSelectedItem();
      }
    });
  }
  
  @override
  void didUpdateWidget(GalleryViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items || 
        widget.selectedItemsPaths != oldWidget.selectedItemsPaths) {
      _filterItems();
      
      // Only scroll if not disposed
      if (!_isDisposed) {
        _scrollToSelectedItem();
      }
    }
  }
  
  @override
  void dispose() {
    // Mark as disposed first to prevent callbacks from running
    _isDisposed = true;
    
    // Cancel any animations to prevent errors
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _pageController.page?.round() ?? 0,
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    }
    
    // Dispose controllers
    _scrubberController.dispose();
    _pageController.dispose();
    
    super.dispose();
  }
  
  void _filterItems() {
    _imageItems = widget.items.where((item) => 
      item.type == FileItemType.file && 
      ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(item.fileExtension.toLowerCase())
    ).toList();
    
    _documentItems = widget.items.where((item) => 
      item.type == FileItemType.file && 
      ['.pdf', '.doc', '.docx', '.txt', '.md', '.xls', '.xlsx', '.ppt', '.pptx'].contains(item.fileExtension.toLowerCase())
    ).toList();
    
    _directoryItems = widget.items.where((item) => 
      item.type == FileItemType.directory
    ).toList();
    
    _otherItems = widget.items.where((item) => 
      !_imageItems.contains(item) && 
      !_documentItems.contains(item) && 
      !_directoryItems.contains(item)
    ).toList();
  }
  
  void _scrollToSelectedItem() {
    if (_isDisposed) return;
    
    if (widget.selectedItemsPaths.isNotEmpty) {
      final selectedPath = widget.selectedItemsPaths.first;
      final index = widget.items.indexWhere((item) => item.path == selectedPath);
      if (index >= 0) {
        setState(() {
          _selectedIndex = index;
        });
        
        // Scroll to the item in the scrubber
        final itemsPerRow = _calculateItemsPerRow();
        if (itemsPerRow > 0 && _scrubberController.hasClients) {
          _scrubberController.animateTo(
            (index ~/ itemsPerRow) * 100.0, // Rough estimate for scroll position
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        
        // Also update the page controller if it has clients
        if (_pageController.hasClients) {
          _pageController.jumpToPage(index);
        }
      }
    }
  }
  
  int _calculateItemsPerRow() {
    // Calculate items per row based on available width
    // This is a rough estimate - for production you would use layout information
    return (MediaQuery.of(context).size.width / 120).floor();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          'No items to display',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Large preview area
        Expanded(
          flex: 4,
          child: _buildPreviewArea(),
        ),
        
        // Divider
        Divider(height: 1),
        
        // Thumbnail scrubber
        SizedBox(
          height: 120,
          child: _buildScrubber(),
        ),
      ],
    );
  }
  
  Widget _buildPreviewArea() {
    // Show the selected item in a large preview
    return GestureDetector(
      onTap: widget.onEmptyAreaTap,
      onSecondaryTapUp: (details) => widget.onEmptyAreaRightClick(details.globalPosition),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          if (_isDisposed) return;
          
          setState(() {
            _selectedIndex = index;
          });
          
          // Update selection
          final item = widget.items[index];
          widget.onItemTap(item, false);
          
          // Scroll scrubber to keep in sync with page view
          int itemsPerRow = _calculateItemsPerRow();
          if (itemsPerRow > 0 && _scrubberController.hasClients) {
            _scrubberController.animateTo(
              (index ~/ itemsPerRow) * 100.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        itemBuilder: (context, index) {
          if (index < 0 || index >= widget.items.length) {
            return Container(); // Safety check
          }
          final item = widget.items[index];
          return _buildLargePreview(context, item);
        },
      ),
    );
  }
  
  Widget _buildLargePreview(BuildContext context, FileItem item) {
    if (item.type == FileItemType.directory) {
      return _buildDirectoryPreview(context, item);
    }
    
    // Image preview for image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(item.fileExtension.toLowerCase())) {
      return _buildImagePreview(context, item);
    }
    
    // Document preview
    if (['.pdf', '.doc', '.docx', '.txt', '.md'].contains(item.fileExtension.toLowerCase())) {
      return _buildDocumentPreview(context, item);
    }
    
    // Generic file preview
    return _buildGenericPreview(context, item);
  }
  
  Widget _buildDirectoryPreview(BuildContext context, FileItem item) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 120,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Folder',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Modified: ${item.formattedModifiedTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview(BuildContext context, FileItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image preview (larger part)
        Expanded(
          child: Center(
            child: Image.file(
              File(item.path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load image',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        
        // Image info (smaller part)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Size: ${item.formattedSize}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Modified: ${item.formattedModifiedTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildActionButton(context, Icons.rotate_left, 'Rotate Left'),
                  const SizedBox(width: 8),
                  _buildActionButton(context, Icons.rotate_right, 'Rotate Right'),
                  const SizedBox(width: 8),
                  _buildActionButton(context, Icons.edit, 'Edit'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDocumentPreview(BuildContext context, FileItem item) {
    IconData iconData;
    Color iconColor;
    String typeText;
    
    switch (item.fileExtension.toLowerCase()) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        typeText = 'PDF Document';
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        typeText = 'Word Document';
        break;
      case '.txt':
      case '.md':
        iconData = Icons.text_snippet;
        iconColor = Colors.blue;
        typeText = 'Text Document';
        break;
      case '.xls':
      case '.xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        typeText = 'Spreadsheet';
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        typeText = 'Presentation';
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
        typeText = 'Document';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 120,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            typeText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Size: ${item.formattedSize}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Modified: ${item.formattedModifiedTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenericPreview(BuildContext context, FileItem item) {
    IconData iconData;
    Color iconColor;
    
    // Determine icon based on file extension
    switch (item.fileExtension.toLowerCase()) {
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.flac':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
        break;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
        iconData = Icons.movie;
        iconColor = Colors.red;
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 120,
            color: iconColor,
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${item.formattedSize}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Modified: ${item.formattedModifiedTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Add action implementation here
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Icon(
              icon,
              size: 20,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildScrubber() {
    return GridView.builder(
      controller: _scrubberController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: 8,
        mainAxisExtent: 100,
      ),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final isSelected = _selectedIndex == index || widget.selectedItemsPaths.contains(item.path);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            });
            widget.onItemTap(item, false);
          },
          onDoubleTap: () => widget.onItemDoubleTap(item),
          onLongPress: () => widget.onItemLongPress(item),
          onSecondaryTapUp: (details) => widget.onItemRightClick(item, details.globalPosition),
          child: _buildThumbnail(context, item, isSelected),
        );
      },
    );
  }
  
  Widget _buildThumbnail(BuildContext context, FileItem item, bool isSelected) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected
            ? (isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1))
            : (isDarkMode ? Colors.grey.shade800 : Colors.white),
      ),
      child: Column(
        children: [
          // Thumbnail
          Expanded(
            child: _buildThumbnailContent(context, item),
          ),
          
          // Filename
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            width: double.infinity,
            color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
            child: Text(
              item.name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThumbnailContent(BuildContext context, FileItem item) {
    // Directory thumbnail
    if (item.type == FileItemType.directory) {
      return Icon(
        Icons.folder,
        size: 40,
        color: Colors.amber,
      );
    }
    
    // Image thumbnail
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(item.fileExtension.toLowerCase())) {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image,
            size: 40,
            color: Colors.blue,
          );
        },
      );
    }
    
    // Other file types
    IconData iconData;
    Color iconColor;
    
    switch (item.fileExtension.toLowerCase()) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case '.mp3':
      case '.wav':
      case '.ogg':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
        break;
      case '.mp4':
      case '.mov':
      case '.avi':
        iconData = Icons.movie;
        iconColor = Colors.red;
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }
    
    return Icon(
      iconData,
      size: 40,
      color: iconColor,
    );
  }
} 