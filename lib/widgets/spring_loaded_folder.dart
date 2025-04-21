import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'folder_drop_target.dart';
import 'dart:async';
import 'package:logging/logging.dart';

/// A widget that wraps a folder drop target with spring-loading functionality.
/// When a user drags over this folder and hovers for a certain time, it will
/// automatically "open" by calling the onOpen callback.
class SpringLoadedFolder extends StatefulWidget {
  final FileItem folder;
  final Widget child;
  final VoidCallback onOpen;
  final VoidCallback? onDropSuccessful;
  final Duration springLoadDelay;
  
  const SpringLoadedFolder({
    super.key,
    required this.folder,
    required this.child,
    required this.onOpen,
    this.onDropSuccessful,
    this.springLoadDelay = const Duration(milliseconds: 800), // Default delay
  });

  @override
  State<SpringLoadedFolder> createState() => _SpringLoadedFolderState();
}

class _SpringLoadedFolderState extends State<SpringLoadedFolder> {
  final _logger = Logger('SpringLoadedFolder');
  Timer? _springLoadTimer;
  bool _isHovering = false;
  
  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
  
  // Cancel the timer if it's running
  void _cancelTimer() {
    _springLoadTimer?.cancel();
    _springLoadTimer = null;
  }
  
  // Start the spring load timer
  void _startTimer() {
    // Cancel any existing timer first
    _cancelTimer();
    
    // Create new timer
    _springLoadTimer = Timer(widget.springLoadDelay, () {
      if (_isHovering && mounted) {
        _logger.fine('Spring-loading folder: ${widget.folder.name}');
        widget.onOpen();
      }
    });
  }
  
  // Handle when dragging enters this folder
  void _onDragEnter() {
    setState(() {
      _isHovering = true;
    });
    _startTimer();
  }
  
  // Handle when dragging leaves this folder
  void _onDragLeave() {
    setState(() {
      _isHovering = false;
    });
    _cancelTimer();
  }
  
  // Handle dropping on this folder
  void _onDrop() {
    _cancelTimer();
    setState(() {
      _isHovering = false;
    });
    
    // Notify parent of successful drop
    widget.onDropSuccessful?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return _DragDetector(
      onDragEnter: _onDragEnter,
      onDragLeave: _onDragLeave,
      child: FolderDropTarget(
        folder: widget.folder,
        onDropSuccessful: _onDrop,
        child: widget.child,
      ),
    );
  }
}

/// A helper widget to detect when drag enters and leaves its bounds
class _DragDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onDragEnter;
  final VoidCallback onDragLeave;
  
  const _DragDetector({
    required this.child,
    required this.onDragEnter,
    required this.onDragLeave,
  });

  @override
  State<_DragDetector> createState() => _DragDetectorState();
}

class _DragDetectorState extends State<_DragDetector> {
  bool _isDragInside = false;
  
  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      builder: (context, candidateData, rejectedData) {
        return widget.child;
      },
      
      onWillAcceptWithDetails: (DragTargetDetails<Object?> details) {
        // Don't actually accept the drop here, just detect entry/exit
        if (!_isDragInside) {
          _isDragInside = true;
          widget.onDragEnter();
        }
        return false; // Never accept the drop here
      },
      
      onLeave: (data) {
        _isDragInside = false;
        widget.onDragLeave();
      },
    );
  }
} 