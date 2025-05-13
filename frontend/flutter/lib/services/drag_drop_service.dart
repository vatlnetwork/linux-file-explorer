import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import 'package:logging/logging.dart';

enum DragOperation { copy, move, link }

class DragDropService extends ChangeNotifier {
  final _logger = Logger('DragDropService');
  
  // Currently dragged items
  List<FileItem>? _draggedItems;
  List<FileItem>? get draggedItems => _draggedItems;
  
  // Current drag operation
  DragOperation _currentOperation = DragOperation.copy;
  DragOperation get currentOperation => _currentOperation;
  
  // Is drag in progress
  bool get isDragging => _draggedItems != null;
  
  // Start dragging
  void startDrag(List<FileItem> items, [DragOperation operation = DragOperation.copy]) {
    _draggedItems = List.from(items);
    _currentOperation = operation;
    _logger.fine('Started dragging ${items.length} items with operation $_currentOperation');
    notifyListeners();
  }
  
  // End dragging
  void endDrag() {
    _draggedItems = null;
    _logger.fine('Ended drag operation');
    notifyListeners();
  }
  
  // Change operation mode (e.g., when user presses modifier keys)
  void setOperation(DragOperation operation) {
    if (_currentOperation != operation) {
      _currentOperation = operation;
      _logger.fine('Changed drag operation to $_currentOperation');
      notifyListeners();
    }
  }
  
  // Check if a drop is valid
  bool canDropOnTarget(FileItem target) {
    // If there are no dragged items, drop is invalid
    if (_draggedItems == null || _draggedItems!.isEmpty) return false;
    
    // If target is not a directory, reject
    if (target.type != FileItemType.directory) return false;
    
    // Check if any item is a parent of target (circular reference)
    for (var item in _draggedItems!) {
      if (_isParentOf(item.path, target.path)) return false;
      
      // Can't drop onto itself
      if (item.path == target.path) return false;
    }
    
    return true;
  }
  
  // Helper to check parent-child relationship
  bool _isParentOf(String parentPath, String childPath) {
    return childPath.startsWith('$parentPath/');
  }
  
  // Static method to access the service
  static DragDropService of(BuildContext context) {
    return Provider.of<DragDropService>(context, listen: false);
  }
} 