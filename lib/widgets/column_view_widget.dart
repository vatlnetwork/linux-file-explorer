import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../services/preview_panel_service.dart';

/// A widget that displays a hierarchical column view of the file system
/// Similar to the macOS Finder's column view
class ColumnViewWidget extends StatefulWidget {
  final String currentPath;
  final List<FileItem> items;
  final Function(String) onNavigate;
  final Function(FileItem, bool) onItemTap;
  final Function(FileItem) onItemDoubleTap;
  final Function(FileItem) onItemLongPress;
  final Function(FileItem, Offset) onItemRightClick;
  final Set<String> selectedItemsPaths;
  final Function() onEmptyAreaTap;
  final Function(Offset) onEmptyAreaRightClick;

  const ColumnViewWidget({
    super.key,
    required this.currentPath,
    required this.items,
    required this.onNavigate,
    required this.onItemTap,
    required this.onItemDoubleTap,
    required this.onItemLongPress,
    required this.onItemRightClick,
    required this.selectedItemsPaths,
    required this.onEmptyAreaTap,
    required this.onEmptyAreaRightClick,
  });

  @override
  State<ColumnViewWidget> createState() => _ColumnViewWidgetState();
}

class _ColumnViewWidgetState extends State<ColumnViewWidget> with AutomaticKeepAliveClientMixin {
  final FileService _fileService = FileService();
  
  // Track the columns to display
  late List<_ColumnData> _columns;
  
  // Selected item in each column
  final Map<int, FileItem?> _selectedItems = {};
  
  // Scroll controllers for each column
  final Map<int, ScrollController> _scrollControllers = {};
  
  // Flag to track if the widget is disposed
  bool _isDisposed = false;
  
  @override
  bool get wantKeepAlive => false; // Don't keep the widget alive when not visible

  @override
  void initState() {
    super.initState();
    _initializeColumns();
  }
  
  @override
  void didUpdateWidget(ColumnViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath || 
        oldWidget.items != widget.items) {
      _initializeColumns();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // Dispose all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    super.dispose();
  }
  
  void _initializeColumns() {
    if (_isDisposed) return;
    
    // Start with the current directory
    _columns = [
      _ColumnData(
        path: widget.currentPath,
        items: widget.items,
      ),
    ];
    
    // Reset selected items
    _selectedItems.clear();
    
    // Create scroll controllers for each column
    _scrollControllers.clear();
    _scrollControllers[0] = ScrollController();
  }
  
  Future<void> _handleItemSelect(int columnIndex, FileItem item) async {
    if (_isDisposed) return;
    
    // Update selection for this column
    setState(() {
      _selectedItems[columnIndex] = item;
      
      // Remove any columns that come after this one
      if (_columns.length > columnIndex + 1) {
        _columns = _columns.sublist(0, columnIndex + 1);
        for (var i = columnIndex + 1; i < _selectedItems.length; i++) {
          _selectedItems.remove(i);
        }
      }
    });
    
    // If this is a directory, load its contents for the next column
    if (item.type == FileItemType.directory) {
      try {
        final items = await _fileService.listDirectory(item.path);
        
        // Check if widget is still mounted before updating state
        if (_isDisposed) return;
        
        // Add a new column with this directory's contents
        setState(() {
          _columns.add(_ColumnData(
            path: item.path,
            items: items,
          ));
          
          // Create a scroll controller for the new column
          _scrollControllers[_columns.length - 1] = ScrollController();
        });
      } catch (e) {
        // Handle error only if still mounted
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading directory: $e')),
          );
        }
      }
    }
    
    // Let the parent know about the selection
    widget.onItemTap(item, false);
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    final bool shouldShowPreview = previewPanelService.showPreviewPanel;
    
    return Row(
      children: [
        // Columns view
        Expanded(
          flex: 7,
          child: _buildColumnsView(),
        ),
        
        // Preview panel if enabled
        if (shouldShowPreview) ...[
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: _buildColumnPreview(),
          ),
        ],
      ],
    );
  }
  
  Widget _buildColumnsView() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _columns.length,
      separatorBuilder: (context, index) => const VerticalDivider(width: 1),
      itemBuilder: (context, index) {
        return SizedBox(
          width: 280,
          child: _buildColumn(index),
        );
      },
    );
  }
  
  Widget _buildColumn(int columnIndex) {
    final columnData = _columns[columnIndex];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFDDEEFF),
          child: Text(
            p.basename(columnData.path),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Column content
        Expanded(
          child: GestureDetector(
            onTap: widget.onEmptyAreaTap,
            onSecondaryTapUp: (details) => widget.onEmptyAreaRightClick(details.globalPosition),
            child: columnData.items.isEmpty
                ? Center(
                    child: Text(
                      'No items',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollControllers[columnIndex],
                    itemCount: columnData.items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = columnData.items[itemIndex];
                      final isSelected = _selectedItems[columnIndex]?.path == item.path || 
                                         widget.selectedItemsPaths.contains(item.path);
                      
                      return _ColumnItemWidget(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => _handleItemSelect(columnIndex, item),
                        onDoubleTap: () => widget.onItemDoubleTap(item),
                        onLongPress: () => widget.onItemLongPress(item),
                        onRightClick: (position) => widget.onItemRightClick(item, position),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildColumnPreview() {
    // Get the selected item for the preview - use the last selected item
    FileItem? selectedItem;
    for (var i = _columns.length - 1; i >= 0; i--) {
      if (_selectedItems.containsKey(i) && _selectedItems[i] != null) {
        selectedItem = _selectedItems[i];
        break;
      }
    }
    
    if (selectedItem == null) {
      return const Center(
        child: Text('No item selected'),
      );
    }
    
    // Show appropriate preview based on item type
    if (selectedItem.type == FileItemType.directory) {
      return _buildDirectoryPreview(selectedItem);
    } else if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(selectedItem.fileExtension.toLowerCase())) {
      return _buildImagePreview(selectedItem);
    } else {
      return _buildGenericPreview(selectedItem);
    }
  }
  
  Widget _buildDirectoryPreview(FileItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basename(item.path),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Folder'),
          const SizedBox(height: 4),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          Center(
            child: Icon(
              Icons.folder_open,
              size: 96,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePreview(FileItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basename(item.path),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text('Size: ${item.formattedSize}'),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Image.file(
                File(item.path),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.red,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenericPreview(FileItem item) {
    IconData iconData;
    Color iconColor;
    String fileType;
    
    // Determine the icon and type based on extension
    switch (item.fileExtension.toLowerCase()) {
      case '.txt':
      case '.md':
        iconData = Icons.description;
        iconColor = Colors.blue;
        fileType = 'Text Document';
        break;
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        fileType = 'PDF Document';
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        fileType = 'Word Document';
        break;
      case '.xls':
      case '.xlsx':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        fileType = 'Spreadsheet';
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        fileType = 'Presentation';
        break;
      case '.mp3':
      case '.wav':
      case '.ogg':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
        fileType = 'Audio File';
        break;
      case '.mp4':
      case '.mov':
      case '.avi':
        iconData = Icons.movie;
        iconColor = Colors.red;
        fileType = 'Video File';
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        iconColor = Colors.brown;
        fileType = 'Archive';
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
        fileType = 'File';
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.basename(item.path),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(fileType),
          Text('Size: ${item.formattedSize}'),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          Center(
            child: Icon(
              iconData,
              size: 96,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnData {
  final String path;
  final List<FileItem> items;
  
  _ColumnData({
    required this.path,
    required this.items,
  });
}

class _ColumnItemWidget extends StatelessWidget {
  final FileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;
  final Function(Offset) onRightClick;
  
  const _ColumnItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onRightClick,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      onSecondaryTapUp: (details) => onRightClick(details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // File icon
            Icon(
              item.type == FileItemType.directory
                  ? Icons.folder
                  : _getIconForFile(item),
              color: item.type == FileItemType.directory
                  ? Colors.amber
                  : _getColorForFile(item),
              size: 20,
            ),
            const SizedBox(width: 8),
            // File name
            Expanded(
              child: Text(
                p.basename(item.path),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Arrow for directories
            if (item.type == FileItemType.directory)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForFile(FileItem item) {
    switch (item.fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return Icons.image;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Icons.music_note;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Icons.movie;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getColorForFile(FileItem item) {
    switch (item.fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return Colors.blue;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Colors.purple;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Colors.red;
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
        return Colors.blue;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Colors.green;
      case '.ppt':
      case '.pptx':
        return Colors.orange;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
} 