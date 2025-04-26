// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';
import '../services/file_service.dart';

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
        return dragDropService.canDropOnTarget(widget.folder);
      },
      
      // Handle when a drag operation enters this target
      onAcceptWithDetails: (DragTargetDetails<FileItem> details) async {
        final draggedItem = details.data;
        if (!mounted) return;
        final dragDropService = DragDropService.of(context);
        final operation = dragDropService.currentOperation;
        
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
                content: Text('Successfully ${operation.name}d ${draggedItem.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Show error message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error ${operation.name}ing ${draggedItem.name}: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }
  
  Color _getBackgroundColor(bool isHovering) {
    if (!isHovering) return Colors.transparent;
    
    final theme = Theme.of(context);
    return theme.colorScheme.primary.withAlpha(25);
  }
} 