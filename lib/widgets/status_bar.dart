import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';

class StatusBar extends StatefulWidget {
  final List<FileItem> items;
  final Set<String> selectedItemsPaths;
  final String currentPath;
  
  const StatusBar({
    super.key,
    required this.items,
    required this.selectedItemsPaths,
    required this.currentPath,
  });

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  // Stats for deep counting
  bool _isCalculating = false;
  int _deepFolderCount = 0;
  int _deepFileCount = 0;
  int _deepTotalSize = 0;
  
  @override
  void initState() {
    super.initState();
    _calculateDeepStats();
  }
  
  @override
  void didUpdateWidget(StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if the directory changed or items changed
    if (oldWidget.currentPath != widget.currentPath ||
        oldWidget.items.length != widget.items.length) {
      _calculateDeepStats();
    }
  }
  
  // Calculate stats for all files including subdirectories
  Future<void> _calculateDeepStats() async {
    if (_isCalculating) return;
    
    setState(() {
      _isCalculating = true;
    });
    
    // Start with surface level counts
    int folderCount = widget.items.where((item) => item.type == FileItemType.directory).length;
    int fileCount = widget.items.length - folderCount;
    int totalSize = widget.items
        .where((item) => item.type == FileItemType.file && item.size != null)
        .fold<int>(0, (sum, item) => sum + (item.size ?? 0));
    
    // Process in a separate isolate or using compute
    try {
      // Get directories to scan
      final directories = widget.items
          .where((item) => item.type == FileItemType.directory)
          .map((item) => item.path)
          .toList();
      
      // Create temporary counts
      int tempFolderCount = folderCount;
      int tempFileCount = fileCount;
      int tempTotalSize = totalSize;
      
      // Scan each top-level directory
      for (final dirPath in directories) {
        try {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            // Stream all entities in the directory tree
            await for (final entity in dir.list(recursive: true)) {
              if (entity is File) {
                tempFileCount++;
                try {
                  final fileSize = await entity.length();
                  tempTotalSize += fileSize;
                } catch (e) {
                  // Skip files with errors
                }
              } else if (entity is Directory) {
                tempFolderCount++;
              }
            }
          }
        } catch (e) {
          // Skip directories we can't access
        }
      }
      
      // Update state if mounted
      if (mounted) {
        setState(() {
          _deepFolderCount = tempFolderCount;
          _deepFileCount = tempFileCount;
          _deepTotalSize = tempTotalSize;
          _isCalculating = false;
        });
      }
    } catch (e) {
      // Fall back to surface counts in case of error
      if (mounted) {
        setState(() {
          _deepFolderCount = folderCount;
          _deepFileCount = fileCount;
          _deepTotalSize = totalSize;
          _isCalculating = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasSelection = widget.selectedItemsPaths.isNotEmpty;
    
    // Count folders and files at the surface level (for display while calculating)
    final surfaceFolderCount = widget.items.where((item) => item.type == FileItemType.directory).length;
    final surfaceFileCount = widget.items.length - surfaceFolderCount;
    
    // Get total size of files at surface level
    final surfaceTotalSize = widget.items
        .where((item) => item.type == FileItemType.file && item.size != null)
        .fold<int>(0, (sum, item) => sum + (item.size ?? 0));
    
    // Get selected items
    final selectedItems = widget.items.where((item) => widget.selectedItemsPaths.contains(item.path)).toList();
    
    // Count selected folders and files
    final selectedFolderCount = selectedItems.where((item) => item.type == FileItemType.directory).length;
    final selectedFileCount = selectedItems.length - selectedFolderCount;
    
    // Get total size of selected files
    final selectedTotalSize = selectedItems
        .where((item) => item.type == FileItemType.file && item.size != null)
        .fold<int>(0, (sum, item) => sum + (item.size ?? 0));
    
    // Use deep stats if available, otherwise use surface stats
    final folderCount = _isCalculating ? surfaceFolderCount : _deepFolderCount;
    final fileCount = _isCalculating ? surfaceFileCount : _deepFileCount;
    final totalSize = _isCalculating ? surfaceTotalSize : _deepTotalSize;
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.black54 : Colors.black12,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Left side: Always show directory content summary if no selection,
          // or selection info if items are selected
          AnimatedCrossFade(
            firstChild: _buildDirectoryInfo(
              folderCount, 
              fileCount, 
              totalSize, 
              isDarkMode,
              _isCalculating
            ),
            secondChild: _buildSelectionInfo(
              selectedFolderCount, 
              selectedFileCount, 
              selectedTotalSize, 
              isDarkMode
            ),
            crossFadeState: hasSelection 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          
          const Spacer(),
          
          // Right side: Always show directory totals, even when items are selected
          hasSelection
              ? Row(
                  children: [
                    Text(
                      'Directory: $folderCount ${folderCount == 1 ? 'folder' : 'folders'}, $fileCount ${fileCount == 1 ? 'file' : 'files'}, ${_formatSize(totalSize)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
  
  // Helper widget to display directory information
  Widget _buildDirectoryInfo(int folderCount, int fileCount, int totalSize, bool isDarkMode, bool isCalculating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}, $fileCount ${fileCount == 1 ? 'file' : 'files'} (includes subdirs)',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Total size: ${_formatSize(totalSize)}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        if (isCalculating) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.blue.shade200 : Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  // Helper widget to display selection information
  Widget _buildSelectionInfo(int folderCount, int fileCount, int totalSize, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 14,
          color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
        ),
        const SizedBox(width: 6),
        Text(
          'Selected: $folderCount ${folderCount == 1 ? 'folder' : 'folders'}, $fileCount ${fileCount == 1 ? 'file' : 'files'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Size: ${_formatSize(totalSize)}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }
  
  // Helper function to format size
  String _formatSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    
    final kb = sizeInBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
} 