// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';
import '../services/file_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/bookmark_service.dart';

class FolderDropTarget extends StatefulWidget {
  final FileItem folder;
  final Widget child;
  final VoidCallback? onDropSuccessful;
  final Function(String)? onNavigateToDirectory;
  
  const FolderDropTarget({
    super.key,
    required this.folder,
    required this.child,
    this.onDropSuccessful,
    this.onNavigateToDirectory,
  });

  @override
  State<FolderDropTarget> createState() => _FolderDropTargetState();
}

class _FolderDropTargetState extends State<FolderDropTarget> {
  final _fileService = FileService();
  Timer? _hoverTimer;
  bool _isHovering = false;
  
  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }
  
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
      onWillAcceptWithDetails: (details) {
        setState(() {
          _isHovering = true;
        });
        
        // Start a timer to transition to this directory after 7 seconds
        _hoverTimer?.cancel();
        _hoverTimer = Timer(const Duration(seconds: 7), () {
          if (mounted && _isHovering) {
            // Use the provided callback to navigate
            widget.onNavigateToDirectory?.call(widget.folder.path);
          }
        });
        return true;
      },
      
      // Handle when a drag operation exits this target
      onLeave: (item) {
        setState(() {
          _isHovering = false;
        });
        _hoverTimer?.cancel();
      },
      
      // Handle when a drag operation is accepted
      onAcceptWithDetails: (details) async {
        if (!mounted) return;
        
        // Show dialog to choose operation
        final operation = await showDialog<DragOperation>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('File Operation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What would you like to do with "${details.data.name}"?'),
                SizedBox(height: 8),
                Text('Target folder: ${widget.folder.name}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, DragOperation.copy),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Copy Here'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, DragOperation.move),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cut, size: 16),
                    SizedBox(width: 8),
                    Text('Move Here'),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          ),
        );
        
        // If no operation was selected (dialog was cancelled), return
        if (operation == null || !mounted) return;
        
        try {
          switch (operation) {
            case DragOperation.copy:
              await _fileService.copyFileOrDirectory(
                details.data.path,
                widget.folder.path,
                handleConflicts: true,
              );
              break;
              
            case DragOperation.move:
              await _fileService.moveFileOrDirectory(
                details.data.path,
                widget.folder.path,
              );
              break;
              
            case DragOperation.link:
              await _fileService.createSymlink(
                details.data.path, 
                '${widget.folder.path}/${details.data.name}',
              );
              break;
          }
          
          // Notify parent of successful drop
          widget.onDropSuccessful?.call();
          
          // Refresh bookmarks if the target folder is a bookmark
          final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
          if (bookmarkService.isBookmarked(widget.folder.path)) {
            bookmarkService.refreshBookmarks();
          }
          
          // Show success message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully ${operation.name}d ${details.data.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Show error message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error ${operation.name}ing ${details.data.name}: $e'),
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