import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';
import 'file_item_widget.dart';
import 'grid_item_widget.dart';

class DraggableFileItem extends StatelessWidget {
  final FileItem item;
  final Function(FileItem, bool) onTap;
  final VoidCallback onDoubleTap;
  final Function(FileItem) onLongPress;
  final Function(FileItem, Offset position) onRightClick;
  final bool isSelected;
  final bool isGridMode;
  
  const DraggableFileItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onRightClick,
    this.isSelected = false,
    this.isGridMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get the drag drop service
    final dragDropService = DragDropService.of(context);
    
    // Check if there are multiple items selected
    final selectedItems = dragDropService.draggedItems;
    final isMultiDrag = selectedItems != null && selectedItems.length > 1;
    
    return Draggable<FileItem>(
      // Data is the file item being dragged
      data: item,
      
      // Feedback is what appears under the cursor during drag
      feedback: Material(
        elevation: 4.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: isMultiDrag ? _buildMultiItemFeedback(context, selectedItems!) : _buildFeedback(context),
      ),
      
      // Child when dragging is the item that stays in place but visually shows it's being dragged
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: isGridMode
            ? GridItemWidget(
                item: item,
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                onLongPress: onLongPress,
                onRightClick: onRightClick,
                isSelected: isSelected,
              )
            : FileItemWidget(
                item: item,
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                onLongPress: onLongPress,
                onRightClick: onRightClick,
                isSelected: isSelected,
              ),
      ),
      
      // The actual widget that can be dragged
      child: isGridMode
          ? GridItemWidget(
              item: item,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onLongPress: onLongPress,
              onRightClick: onRightClick,
              isSelected: isSelected,
            )
          : FileItemWidget(
              item: item,
              onTap: onTap,
              onDoubleTap: onDoubleTap,
              onLongPress: onLongPress,
              onRightClick: onRightClick,
              isSelected: isSelected,
            ),
      
      // When drag starts
      onDragStarted: () {
        final dragDropService = DragDropService.of(context);
        // If this item is selected, drag all selected items
        if (isSelected) {
          final selectedItems = dragDropService.draggedItems;
          if (selectedItems != null && selectedItems.isNotEmpty) {
            dragDropService.startDrag(selectedItems);
          } else {
            dragDropService.startDrag([item]);
          }
        } else {
          dragDropService.startDrag([item]);
        }
      },
      
      // When drag ends without dropping on valid target
      onDraggableCanceled: (_, __) {
        final dragDropService = DragDropService.of(context);
        dragDropService.endDrag();
      },
      
      // When drag completes with a successful drop
      onDragCompleted: () {
        final dragDropService = DragDropService.of(context);
        dragDropService.endDrag();
      },
    );
  }
  
  // Build the visual feedback during drag
  Widget _buildFeedback(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF333333) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon based on file type
          item.type == FileItemType.directory
              ? const Icon(Icons.folder, color: Colors.blue, size: 24)
              : _getFileTypeIcon(),
          
          const SizedBox(width: 8),
          
          // File name with max width constraint
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to get icon based on file type
  Widget _getFileTypeIcon() {
    // Determine icon based on file extension
    IconData iconData;
    Color iconColor;
    
    switch (item.fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
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
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case '.doc':
      case '.docx':
      case '.odt':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
      case '.ods':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case '.ppt':
      case '.pptx':
      case '.odp':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case '.txt':
      case '.md':
        iconData = Icons.text_snippet;
        iconColor = Colors.blueGrey;
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        iconColor = Colors.amber;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.blueGrey;
    }
    
    return Icon(iconData, color: iconColor, size: 24);
  }
  
  // Build the visual feedback for multiple items during drag
  Widget _buildMultiItemFeedback(BuildContext context, List<FileItem> items) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF333333) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stack of icons for the first few items
          SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < items.length && i < 3; i++)
                  Positioned(
                    left: i * 8.0,
                    child: Icon(
                      items[i].type == FileItemType.directory ? Icons.folder : Icons.insert_drive_file,
                      color: items[i].type == FileItemType.directory ? Colors.blue : Colors.grey,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Number of items text
          Text(
            '${items.length} items',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
} 