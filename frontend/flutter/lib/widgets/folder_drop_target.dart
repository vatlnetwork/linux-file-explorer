// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';
import '../services/file_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../services/bookmark_service.dart';
import '../widgets/settings/addons_settings.dart';

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
      onWillAcceptWithDetails: (details) {
        setState(() {
          _isHovering = true;
        });
        return true;
      },

      // Handle when a drag operation exits this target
      onLeave: (item) {
        setState(() {
          _isHovering = false;
        });
      },

      // Handle when a drag operation is accepted
      onAcceptWithDetails: (details) async {
        if (!mounted) return;

        // Get the drag drop service
        final dragDropService = DragDropService.of(context);
        final draggedItems = dragDropService.draggedItems;

        if (draggedItems == null || draggedItems.isEmpty) return;

        // Get the context menu settings
        final contextMenuSettings = Provider.of<ContextMenuSettings>(
          context,
          listen: false,
        );

        // Determine the operation based on settings and current drag operation
        DragOperation operation;

        if (contextMenuSettings.isEnabled('drag_drop_dialog')) {
          // Show dialog to choose operation
          operation =
              await showDialog<DragOperation>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text('File Operation'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What would you like to do with ${draggedItems.length} items?',
                          ),
                          SizedBox(height: 8),
                          Text('Target folder: ${widget.folder.name}'),
                          if (draggedItems.length > 1) ...[
                            SizedBox(height: 8),
                            Text(
                              'First few items:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            for (
                              var i = 0;
                              i < draggedItems.length && i < 3;
                              i++
                            )
                              Text(
                                '• ${draggedItems[i].name}',
                                style: TextStyle(fontSize: 12),
                              ),
                            if (draggedItems.length > 3)
                              Text(
                                '... and ${draggedItems.length - 3} more',
                                style: TextStyle(fontSize: 12),
                              ),
                          ],
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed:
                              () => Navigator.pop(context, DragOperation.copy),
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
                          onPressed:
                              () => Navigator.pop(context, DragOperation.move),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
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
              ) ??
              dragDropService.currentOperation;
        } else {
          // Use the current operation from the drag drop service
          operation = dragDropService.currentOperation;
        }

        // If no operation was selected (dialog was cancelled), return
        if (!mounted) return;

        try {
          // Show progress dialog for multiple items
          if (draggedItems.length > 1 && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    operation == DragOperation.copy
                        ? 'Copying Files'
                        : 'Moving Files',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing ${draggedItems.length} items...'),
                    ],
                  ),
                );
              },
            );
          }

          // Process each item
          for (final item in draggedItems) {
            switch (operation) {
              case DragOperation.copy:
                await _fileService.copyFileOrDirectory(
                  item.path,
                  widget.folder.path,
                  handleConflicts: true,
                );
                break;

              case DragOperation.move:
                await _fileService.moveFileOrDirectory(
                  item.path,
                  widget.folder.path,
                );
                break;

              case DragOperation.link:
                await _fileService.createSymlink(
                  item.path,
                  '${widget.folder.path}/${item.name}',
                );
                break;
            }
          }

          // Dismiss progress dialog if it was shown
          if (draggedItems.length > 1 && mounted) {
            Navigator.of(context).pop();
          }

          // Notify parent of successful drop
          widget.onDropSuccessful?.call();

          // Refresh bookmarks if the target folder is a bookmark
          final bookmarkService = Provider.of<BookmarkService>(
            context,
            listen: false,
          );
          if (bookmarkService.isBookmarked(widget.folder.path)) {
            bookmarkService.refreshBookmarks();
          }

          // Show success message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Successfully ${operation.name}d ${draggedItems.length} items',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Dismiss progress dialog if it was shown
          if (draggedItems.length > 1 && mounted) {
            Navigator.of(context).pop();
          }

          // Show error message if widget is still mounted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error ${operation.name}ing items: $e'),
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
