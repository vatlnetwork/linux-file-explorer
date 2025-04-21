import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';
import '../services/file_service.dart';
import 'package:logging/logging.dart';

class FolderDropTarget extends StatefulWidget {
  final FileItem folder;
  final Widget child;
  final VoidCallback? onDropSuccessful;
  
  const FolderDropTarget({
    super.key,
    required this.folder,
    required this.child,
    this.onDropSuccessful,
  });

  @override
  State<FolderDropTarget> createState() => _FolderDropTargetState();
}

class _FolderDropTargetState extends State<FolderDropTarget> {
  final _fileService = FileService();
  final _logger = Logger('FolderDropTarget');
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    // Only accept folders as drop targets
    if (widget.folder.type != FileItemType.directory) {
      return widget.child;
    }
    
    return DragTarget<FileItem>(
      builder: (context, candidateItems, rejectedItems) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: _getBackgroundColor(candidateItems.isNotEmpty),
          ),
          child: widget.child,
        );
      },
      
      // Check if we'll accept this item before it's dropped
      onWillAcceptWithDetails: (DragTargetDetails<FileItem?> details) {
        final draggedItem = details.data;
        if (draggedItem == null) return false;
        
        // Get the drag/drop service to check validity
        final dragDropService = DragDropService.of(context);
        final isValid = dragDropService.canDropOnTarget(widget.folder);
        
        // Update hover state for visual feedback
        setState(() => _isHovering = isValid);
        
        return isValid;
      },
      
      // Handle when a drag operation enters this target
      onAcceptWithDetails: (DragTargetDetails<FileItem> details) async {
        final draggedItem = details.data;
        final dragDropService = DragDropService.of(context);
        final operation = dragDropService.currentOperation;
        
        _logger.info('Dropping item ${draggedItem.name} to folder ${widget.folder.name} with operation $operation');
        
        try {
          switch (operation) {
            case DragOperation.copy:
              await _fileService.copyFile(
                draggedItem.path, 
                '${widget.folder.path}/${draggedItem.name}',
              );
              break;
              
            case DragOperation.move:
              await _fileService.moveFile(
                draggedItem.path, 
                '${widget.folder.path}/${draggedItem.name}',
              );
              break;
              
            case DragOperation.link:
              await _fileService.createSymlink(
                draggedItem.path, 
                '${widget.folder.path}/${draggedItem.name}',
              );
              break;
          }
          
          // Notify parent of successful drop
          widget.onDropSuccessful?.call();
          
          // Show success message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_getOperationText(operation)} ${draggedItem.name} to ${widget.folder.name}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          _logger.severe('Error during drop operation: $e');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        
        setState(() => _isHovering = false);
      },
      
      // When drag leaves this target without dropping
      onLeave: (FileItem? item) {
        setState(() => _isHovering = false);
      },
    );
  }
  
  // Get appropriate background color based on drag state
  Color _getBackgroundColor(bool isDragAccepted) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (!_isHovering) {
      return Colors.transparent;
    }
    
    if (isDragAccepted) {
      return isDarkMode 
          ? Colors.blue.shade700.withValues(alpha: 0.2)
          : Colors.blue.shade100.withValues(alpha: 0.7);
    }
    
    return Colors.transparent;
  }
  
  // Helper to get text description of operation
  String _getOperationText(DragOperation operation) {
    switch (operation) {
      case DragOperation.copy:
        return 'Copied';
      case DragOperation.move:
        return 'Moved';
      case DragOperation.link:
        return 'Linked';
    }
  }
} 