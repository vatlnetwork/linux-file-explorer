import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/file_item.dart';
import '../services/drag_drop_service.dart';

class MultiDraggableFiles extends StatefulWidget {
  final List<FileItem> selectedItems;
  final Widget child;

  const MultiDraggableFiles({
    super.key,
    required this.selectedItems,
    required this.child,
  });

  @override
  State<MultiDraggableFiles> createState() => _MultiDraggableFilesState();
}

class _MultiDraggableFilesState extends State<MultiDraggableFiles> {
  DragOperation _currentOperation = DragOperation.move;

  @override
  void initState() {
    super.initState();

    // Setup keyboard listeners for modifier keys
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    // Clean up keyboard listeners
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  // Handle keyboard events for modifier keys to change drag operation
  bool _handleKeyEvent(KeyEvent event) {
    // Check for key down or key up of modifier keys
    if (event is KeyDownEvent || event is KeyUpEvent) {
      // Check current state of modifier keys
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isAltPressed = HardwareKeyboard.instance.isAltPressed;

      // Determine operation based on modifiers
      DragOperation newOperation;

      if (isControlPressed && isAltPressed) {
        // Ctrl+Alt = Link (like in Linux file managers)
        newOperation = DragOperation.link;
      } else if (isControlPressed) {
        // Ctrl = Copy (common in Linux file managers)
        newOperation = DragOperation.copy;
      } else {
        // Default operation (no modifiers)
        newOperation = DragOperation.move;
      }

      // Update operation if changed
      if (newOperation != _currentOperation) {
        setState(() {
          _currentOperation = newOperation;
        });

        // Also update in the service if a drag is in progress
        if (mounted) {
          final dragDropService = DragDropService.of(context);
          if (dragDropService.isDragging) {
            dragDropService.setOperation(newOperation);
          }
        }
      }
    }

    // Return false to allow the event to continue propagating
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // If no items or just one item, don't enable multi-drag
    if (widget.selectedItems.isEmpty || widget.selectedItems.length == 1) {
      return widget.child;
    }

    return Draggable<List<FileItem>>(
      // Data is the list of file items being dragged
      data: widget.selectedItems,

      // Feedback is what appears under the cursor during drag
      feedback: Material(
        elevation: 4.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: _buildFeedback(context),
      ),

      // Child when dragging is the original widget with reduced opacity
      childWhenDragging: Opacity(opacity: 0.5, child: widget.child),

      // The actual widget that can be dragged
      child: widget.child,

      // When drag starts
      onDragStarted: () {
        final dragDropService = DragDropService.of(context);
        dragDropService.startDrag(widget.selectedItems, _currentOperation);
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Color(0xFF333333) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getOperationColor().withValues(alpha: 0.5),
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
          // Operation icon
          Icon(_getOperationIcon(), color: _getOperationColor(), size: 22),

          const SizedBox(width: 12),

          // Number of items and operation text
          Text(
            '${widget.selectedItems.length} items',
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

  // Get color based on operation type
  Color _getOperationColor() {
    switch (_currentOperation) {
      case DragOperation.copy:
        return Colors.blue;
      case DragOperation.move:
        return Colors.orange;
      case DragOperation.link:
        return Colors.purple;
    }
  }

  // Get icon based on operation type
  IconData _getOperationIcon() {
    switch (_currentOperation) {
      case DragOperation.copy:
        return Icons.copy;
      case DragOperation.move:
        return Icons.cut;
      case DragOperation.link:
        return Icons.link;
    }
  }
}
