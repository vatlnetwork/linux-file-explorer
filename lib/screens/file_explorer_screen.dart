// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:window_manager/window_manager.dart';
import 'package:logging/logging.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import '../services/view_mode_service.dart';
import '../services/status_bar_service.dart';
import '../services/icon_size_service.dart';
import '../services/usb_drive_service.dart';
import '../services/preview_panel_service.dart';
import '../services/app_service.dart';
import '../services/file_association_service.dart';
import '../services/quick_look_service.dart';
import '../widgets/split_folder_view.dart';
import '../widgets/bookmark_sidebar.dart';
import '../widgets/status_bar.dart';
import '../widgets/preview_panel.dart';
import '../widgets/app_selection_dialog.dart';
import '../widgets/column_view_widget.dart';
import '../widgets/search_dialog.dart';
import 'file_associations_screen.dart';
import '../widgets/draggable_file_item.dart';
import '../widgets/folder_drop_target.dart';
import '../services/compression_service.dart';
import '../services/tab_manager_service.dart';
import '../widgets/tab_bar.dart';
import '../widgets/keyboard_shortcuts_dialog.dart';

/// A file explorer screen that displays files and folders in a customizable interface.
/// 
/// Key interactions:
/// - Single click: Selects files and folders
/// - Double click: Opens files with default applications or navigates into folders
/// - Right click: Shows context menu for file operations
/// - Ctrl+click: Enables multi-selection of files and folders

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen>
    with TickerProviderStateMixin, WindowListener {
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();
  late FocusNode _focusNode; // Changed from final to late
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  final _logger = Logger('FileExplorerScreen');
  final bool _isSearchActive = false;
  // Setup animation controller for bookmarks sidebar
  late AnimationController _bookmarkSidebarAnimation;
  // Animation controller for preview panel
  late AnimationController _previewPanelAnimation;
  
  String _currentPath = '';
  List<FileItem> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final List<String> _navigationHistory = [];
  final List<String> _forwardHistory = []; // Add forward history
  bool _showBookmarkSidebar = true;
  bool _isMaximized = false;
  
  // Replace single item selection with a set for multiple selection
  Set<String> _selectedItemsPaths = {}; // Track the currently selected items by path
  
  // Replace clipboard and clipboard state variables
  List<FileItem>? _clipboardItems;
  bool _isItemCut = false; // false for copy, true for cut

  // Add UsbDriveService
  final UsbDriveService _usbDriveService = UsbDriveService();

  // Add a key for the breadcrumb bar
  final GlobalKey _breadcrumbKey = GlobalKey();

  // Added state variables for drag selection
  // State variables for drag selection
  Offset? _dragStartPosition;
  Offset? _dragEndPosition;
  final Map<String, Rect> _itemPositions = {}; // Store positions of items for hit testing
  bool _mightStartDragging = false;
  bool _showHiddenFiles = false; // Add state variable for hidden files visibility

  @override
  void initState() {
    super.initState();
    _selectedItemsPaths = {};
    _clipboardItems = [];
    
    // Initialize animation controllers
    _bookmarkSidebarAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _previewPanelAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    windowManager.addListener(this);
    _initWindowState();
    _initHomeDirectory();
    
    // Initialize focus node
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      _logger.info('Focus changed: ${_focusNode.hasFocus}');
    });
    
    // Add a post-frame callback to subscribe to preview panel changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
      previewPanelService.addListener(_handlePreviewPanelChange);
      
      // Initialize first tab
      final tabManager = Provider.of<TabManagerService>(context, listen: false);
      if (tabManager.tabs.isEmpty) {
        tabManager.addTab(_currentPath);
      }
      
      // Add listener for tab changes
      tabManager.addListener(_handleTabChange);
      
      // Request focus after initialization
      _focusNode.requestFocus();
      _logger.info('Requested focus after initialization');
    });
  }

  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bookmarkSidebarAnimation.dispose();
    _previewPanelAnimation.dispose();
    windowManager.removeListener(this);
    _scrollController.dispose();
    _focusNode.dispose(); // Dispose the focus node
    
    // Remove preview panel listener
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    previewPanelService.removeListener(_handlePreviewPanelChange);
    
    // Remove tab manager listener
    final tabManager = Provider.of<TabManagerService>(context, listen: false);
    tabManager.removeListener(_handleTabChange);
    
    super.dispose();
  }
  
  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _initHomeDirectory() async {
    try {
      final String homeDir = await _fileService.getHomeDirectory();
      setState(() {
        _currentPath = homeDir;
      });
      final tabManager = Provider.of<TabManagerService>(context, listen: false);
      tabManager.updateCurrentTabLoading(true);
      _loadDirectory(homeDir, addToHistory: false);
    } catch (e) {
      _handleError('Failed to get home directory: $e');
    }
  }

  Future<void> _loadDirectory(String path, {bool addToHistory = true}) async {
    // Record current path in history if different
    if (addToHistory && _currentPath != path && _currentPath.isNotEmpty) {
      _navigationHistory.add(_currentPath);
      _forwardHistory.clear(); // Clear forward history when navigating to a new path
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _currentPath = path;
      
      // Clear item positions when changing directory since items will be different
      _itemPositions.clear();
      _dragStartPosition = null;
      _dragEndPosition = null;
      _mightStartDragging = false;
    });

    try {
      final items = await _fileService.listDirectory(path, showHidden: _showHiddenFiles);
      
      setState(() {
        _items = items;
        _isLoading = false;
        
        // Reset selection when changing directories
        _selectedItemsPaths = {};
      });

      // Update current tab path
      final tabManager = Provider.of<TabManagerService>(context, listen: false);
      tabManager.updateCurrentTabPath(path);
    } catch (e) {
      // Show error notification
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to load directory: $e',
          type: NotificationType.error,
        );
      }

      // Navigate back to previous directory if available
      if (_navigationHistory.isNotEmpty) {
        final previousPath = _navigationHistory.removeLast();
        _loadDirectory(previousPath, addToHistory: false);
      } else {
        // If no history, just show error state
        _handleError('Failed to load directory: $e');
        final tabManager = Provider.of<TabManagerService>(context, listen: false);
        tabManager.updateCurrentTabError(true, 'Failed to load directory: $e');
      }
    }
  }

  void _handleError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _navigateToDirectory(String path) {
    final tabManager = Provider.of<TabManagerService>(context, listen: false);
    tabManager.updateCurrentTabLoading(true);
    _loadDirectory(path);
  }

  void _navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      // Add current path to forward history
      _forwardHistory.add(_currentPath);
      // Navigate to previous path
      final previousPath = _navigationHistory.removeLast();
      final tabManager = Provider.of<TabManagerService>(context, listen: false);
      tabManager.updateCurrentTabLoading(true);
      _loadDirectory(previousPath, addToHistory: false);
    }
  }

  void _navigateForward() {
    if (_forwardHistory.isNotEmpty) {
      // Add current path to backward history
      _navigationHistory.add(_currentPath);
      // Navigate to forward path
      final forwardPath = _forwardHistory.removeLast();
      final tabManager = Provider.of<TabManagerService>(context, listen: false);
      tabManager.updateCurrentTabLoading(true);
      _loadDirectory(forwardPath, addToHistory: false);
    }
  }

  Future<void> _showCreateDialog(bool isDirectory) async {
    final TextEditingController nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create ${isDirectory ? 'Directory' : 'File'}'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: isDirectory ? 'Enter directory name' : 'Enter file name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        if (isDirectory) {
          await _fileService.createDirectory(_currentPath, result);
        } else {
          await _fileService.createFile(_currentPath, result);
        }
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Error: $e',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  Future<void> _showRenameDialog(FileItem item) async {
    final TextEditingController nameController = TextEditingController(text: item.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'New name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != item.name) {
      try {
        await _fileService.rename(item.path, result);
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Error: $e',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(FileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.type == FileItemType.directory ? 'Directory' : 'File'}'),
        content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fileService.deleteFileOrDirectory(item.path);
        _loadDirectory(_currentPath);
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Error: $e',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  void _selectItem(FileItem item, [bool multiSelect = false]) {
    final String itemPath = item.path;
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    
    setState(() {
      if (multiSelect) {
        // Multi-select logic (when holding Ctrl/Cmd)
        if (_selectedItemsPaths.contains(itemPath)) {
          _selectedItemsPaths.remove(itemPath);
          
          // If we removed the current preview item, try to set a new one
          if (previewPanelService.selectedItem?.path == itemPath) {
            if (_selectedItemsPaths.isNotEmpty) {
              final firstSelectedPath = _selectedItemsPaths.first;
              final firstSelectedItem = _items.firstWhere(
                (item) => item.path == firstSelectedPath,
                orElse: () => FileItem(
                  path: '',
                  name: '',
                  type: FileItemType.unknown,
                ),
              );
              
              if (firstSelectedItem.type != FileItemType.unknown) {
                previewPanelService.setSelectedItem(firstSelectedItem);
              } else {
                previewPanelService.setSelectedItem(null);
              }
            } else {
              previewPanelService.setSelectedItem(null);
            }
          }
        } else {
          _selectedItemsPaths.add(itemPath);
          
          // If this is the first item or we're replacing a previous selection, update preview
          if (_selectedItemsPaths.length == 1 || previewPanelService.selectedItem == null) {
            previewPanelService.setSelectedItem(item);
          }
        }
      } else {
        // Single-selection mode (no Ctrl key)
        setState(() {
          // Just select the item without navigating
          _selectedItemsPaths = {itemPath};
          
          // Set selected item for preview
          previewPanelService.setSelectedItem(item);
        });
      }
    });
  }
  
  void _handleItemDoubleTap(FileItem item) {
    // For files, try to open them, for directories navigate into them
    if (item.type == FileItemType.directory) {
      _navigateToDirectory(item.path);
    } else {
      // Check if there's a default app for this file type
      final fileAssociationService = Provider.of<FileAssociationService>(context, listen: false);
      
      // Get the default app desktop file path for this file
      final defaultAppPath = fileAssociationService.getDefaultAppForFile(item.path);
      
      if (defaultAppPath != null) {
        // Use gtk-launch to open the file with the default app
        try {
          final desktopFileName = defaultAppPath.split('/').last;
          Process.start('gtk-launch', [desktopFileName, item.path]);
        } catch (e) {
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: 'Failed to open file with default app: $e',
              type: NotificationType.error,
            );
          }
        }
      } else {
        // Handle file open using the platform's default application if no custom default is set
        try {
          Process.start('xdg-open', [item.path]);
        } catch (e) {
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: 'Failed to open file: $e',
              type: NotificationType.error,
            );
          }
        }
      }
    }
  }

  bool _isCompressedFile(FileItem item) {
    if (item.type != FileItemType.file) return false;
    final ext = item.fileExtension.toLowerCase();
    return ['.zip', '.rar', '.tar', '.gz', '.7z', '.bz2'].contains(ext);
  }

  void _showContextMenu(FileItem item, Offset position) async {
    // Select the item when right-clicked
    setState(() {
      // If the item is already part of the current multi-selection, keep all selected
      if (!_selectedItemsPaths.contains(item.path)) {
        _selectedItemsPaths = {item.path};
      }
    });
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
    final isFolder = item.type == FileItemType.directory;
    final isBookmarked = isFolder ? bookmarkService.isBookmarked(item.path) : false;
    final isCompressed = _isCompressedFile(item);
    
    // Check if this directory is a mount point
    bool isMountPoint = false;
    if (isFolder) {
      isMountPoint = await _isDirectoryMountPoint(item.path);
    }
    
    // Create a relative rectangle for positioning the menu
    final RelativeRect menuPosition = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
    );
    
    // Add mounted check
    if (!mounted) return;
    
    // Create menu items depending on whether we have multiple items selected
    final hasMultipleSelection = _selectedItemsPaths.length > 1;
    
    final menuItems = <PopupMenuEntry<String>>[
      // Show number of selected items when multiple are selected
      if (hasMultipleSelection)
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            '${_selectedItemsPaths.length} items selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      
      // Open option (only for single item)
      if (!hasMultipleSelection)
        PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 16),
              SizedBox(width: 8),
              Text('Open'),
            ],
          ),
        ),
      
      // Open with option (only for files, not directories)
      if (!hasMultipleSelection && item.type != FileItemType.directory)
        PopupMenuItem<String>(
          value: 'open_with',
          child: Row(
            children: [
              Icon(Icons.apps, size: 16),
              SizedBox(width: 8),
              Text('Open with...'),
            ],
          ),
        ),
        
      // Add common operations for both single and multiple selections
      PopupMenuItem<String>(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy, size: 16),
            SizedBox(width: 8),
            Text(hasMultipleSelection ? 'Copy Items' : 'Copy'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'cut',
        child: Row(
          children: [
            Icon(Icons.cut, size: 16),
            SizedBox(width: 8),
            Text(hasMultipleSelection ? 'Cut Items' : 'Cut'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text(
              hasMultipleSelection ? 'Delete Items' : 'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
      
      // Single item specific options
      if (!hasMultipleSelection) ...[
        const PopupMenuDivider(),
        // Rename option (not for mount points)
        if (!isMountPoint)
          PopupMenuItem<String>(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
        
        // Add/remove bookmark (directories only)
        if (isFolder)
          PopupMenuItem<String>(
            value: isBookmarked ? 'remove_bookmark' : 'bookmark',
            child: Row(
              children: [
                Icon(isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add, size: 16),
                SizedBox(width: 8),
                Text(isBookmarked ? 'Remove Bookmark' : 'Add Bookmark'),
              ],
            ),
          ),
          
        // Terminal option (directories only)
        if (isFolder)
          PopupMenuItem<String>(
            value: 'terminal',
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16),
                SizedBox(width: 8),
                Text('Open in Terminal'),
              ],
            ),
          ),
          
        // Unmount option (mount points only)
        if (isMountPoint)
          PopupMenuItem<String>(
            value: 'unmount',
            child: Row(
              children: [
                Icon(Icons.eject, size: 16),
                SizedBox(width: 8),
                Text('Unmount Drive'),
              ],
            ),
          ),
          
        // Extract option (compressed files only)
        if (isCompressed)
          PopupMenuItem<String>(
            value: 'extract',
            child: Row(
              children: [
                Icon(Icons.file_download, size: 16),
                SizedBox(width: 8),
                Text('Extract'),
              ],
            ),
          ),
          
        // Compress option (for both files and folders, but not for already compressed files)
        if (!_isCompressedFile(item))
          PopupMenuItem<String>(
            value: 'compress',
            child: Row(
              children: [
                Icon(Icons.archive, size: 16),
                SizedBox(width: 8),
                Text('Compress'),
              ],
            ),
          ),
          
        PopupMenuItem<String>(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.paste, size: 16),
              SizedBox(width: 8),
              Text('Paste'),
            ],
          ),
        ),
      ],
    ];
    
    // Add mounted check again
    if (!mounted) return;
    
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF2D2E30)
          : Colors.white,
      items: menuItems,
    );
    
    // Process the selected menu option
    if (result == null || !mounted) return;
    
    // Handle operations for both single and multiple selections
    switch (result) {
      case 'open':
        _handleItemDoubleTap(item);
        break;
      case 'open_with':
        _showOpenWithDialog(item);
        break;
      case 'copy':
        if (hasMultipleSelection) {
          _copyMultipleItems();
        } else {
          _copyItem(item);
        }
        break;
      case 'cut':
        if (hasMultipleSelection) {
          _cutMultipleItems();
        } else {
          _cutItem(item);
        }
        break;
      case 'delete':
        if (hasMultipleSelection) {
          _showDeleteMultipleConfirmation();
        } else {
          _showDeleteConfirmation(item);
        }
        break;
      case 'rename':
        _showRenameDialog(item);
        break;
      case 'bookmark':
        bookmarkService.addBookmark(item);
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Added bookmark: ${item.name}',
            type: NotificationType.success,
          );
        }
        break;
      case 'remove_bookmark':
        bookmarkService.removeBookmark(item.path);
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Removed bookmark: ${item.name}',
            type: NotificationType.success,
          );
        }
        break;
      case 'terminal':
        _openInTerminal(item);
        break;
      case 'unmount':
        _showUnmountConfirmation(item);
        break;
      case 'extract':
        _extractFile(item);
        break;
      case 'paste':
        _pasteFromSystemClipboard();
        break;
      case 'compress':
        if (hasMultipleSelection) {
          _compressMultipleItems(context);
        } else {
          _compressItem(context, item);
        }
        break;
    }
  }

  Future<void> _showDeleteMultipleConfirmation() async {
    if (_selectedItemsPaths.isEmpty) return;
    
    final items = _items.where((item) => _selectedItemsPaths.contains(item.path)).toList();
    final numFiles = items.where((item) => item.type == FileItemType.file).length;
    final numFolders = items.where((item) => item.type == FileItemType.directory).length;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Multiple Items'),
        content: Text(
          'Are you sure you want to delete ${items.length} items '
          '($numFiles files, $numFolders folders)? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show progress dialog for multiple deletions
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: Text('Deleting Files'),
              content: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(width: 16),
                  Text('Deleting ${items.length} items...'),
                ],
              ),
            );
          },
        );
      }
      
      try {
        // Delete each item
        for (final item in items) {
          await _fileService.deleteFileOrDirectory(item.path);
        }
        
        // Dismiss progress dialog
        if (mounted) {
          Navigator.pop(context);
        }
        
        // Reload directory
        _loadDirectory(_currentPath);
        
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Deleted ${items.length} items',
            type: NotificationType.success,
          );
        }
      } catch (e) {
        // Dismiss progress dialog on error
        if (mounted) {
          Navigator.pop(context);
          NotificationService.showNotification(
            context,
            message: 'Error: $e',
            type: NotificationType.error,
          );
        }
      }
    }
  }
  
  void _copyItem(FileItem item) {
    setState(() {
      _clipboardItems = [item];
      _isItemCut = false;
    });
    
    // Copy the path to the system clipboard
    FlutterClipboard.copy(item.path).then((result) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Copied to clipboard: ${item.name}',
          type: NotificationType.info,
        );
      }
    });
  }
  
  void _cutItem(FileItem item) {
    setState(() {
      _clipboardItems = [item];
      _isItemCut = true;
    });
    
    // Copy the path to the system clipboard with a prefix indicating it's a cut operation
    // This is just to provide data to the system clipboard - the cut operation is still handled internally
    FlutterClipboard.copy("CUT:${item.path}").then((result) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Cut to clipboard: ${item.name}',
          type: NotificationType.info,
        );
      }
    });
  }
  
  Future<void> _pasteItemsToCurrentDirectory() async {
    await _pasteItemsFromInternalClipboard();
  }

  Future<void> _pasteFromSystemClipboard() async {
    // First try to use internal clipboard
    if (_clipboardItems != null && _clipboardItems!.isNotEmpty) {
      await _pasteItemsFromInternalClipboard();
      return;
    }
    
    try {
      // Get data from system clipboard
      final String clipboardData = await FlutterClipboard.paste();
      
      if (clipboardData.isEmpty) {
        // Nothing to paste
        return;
      }
      
      // Check if it's a cut operation
      bool isCut = false;
      String processedData = clipboardData;
      
      if (clipboardData.startsWith("CUT:")) {
        isCut = true;
        // Remove the CUT: prefix
        if (clipboardData.startsWith("CUT:\n")) {
          processedData = clipboardData.substring(5); // Skip "CUT:\n"
        } else {
          processedData = clipboardData.substring(4); // Skip "CUT:"
        }
      }
      
      // Split by newlines to get multiple paths
      final List<String> paths = processedData.split('\n')
          .where((path) => path.trim().isNotEmpty)
          .toList();
      
      if (paths.isEmpty) return;
      
      // Create temporary FileItems for these paths
      final List<FileItem> tempClipboardItems = [];
      
      for (final path in paths) {
        if (FileSystemEntity.isFileSync(path)) {
          final file = File(path);
          final stat = file.statSync();
          tempClipboardItems.add(FileItem(
            path: path,
            name: p.basename(path),
            type: FileItemType.file,
            modifiedTime: stat.modified,
            size: stat.size,
          ));
        } else if (FileSystemEntity.isDirectorySync(path)) {
          final dir = Directory(path);
          final stat = dir.statSync();
          tempClipboardItems.add(FileItem(
            path: path,
            name: p.basename(path),
            type: FileItemType.directory,
            modifiedTime: stat.modified,
          ));
        }
      }
      
      // If we have valid items, temporarily set them as clipboard items and paste
      if (tempClipboardItems.isNotEmpty) {
        // Save the current clipboard state
        final oldClipboardItems = _clipboardItems;
        final oldIsItemCut = _isItemCut;
        
        // Temporarily set the new clipboard data
        setState(() {
          _clipboardItems = tempClipboardItems;
          _isItemCut = isCut;
        });
        
        // Paste using the internal paste method
        await _pasteItemsFromInternalClipboard();
        
        // Restore previous clipboard if it was a copy operation
        // or if it was a cut but the operation failed
        if (!isCut) {
          setState(() {
            _clipboardItems = oldClipboardItems;
            _isItemCut = oldIsItemCut;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Error pasting from system clipboard: $e',
          type: NotificationType.error,
        );
      }
    }
  }
  
  Future<void> _pasteItemsFromInternalClipboard() async {
    if (_clipboardItems == null || _clipboardItems!.isEmpty) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'No items to paste',
          type: NotificationType.info,
        );
      }
      return;
    }
    
    try {
      // Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text(_isItemCut ? 'Moving Files' : 'Copying Files'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing files...'),
                    ],
                  ),
                );
              },
            );
          },
        );
      }
      
      final sourcePaths = _clipboardItems!.map((item) => item.path).toList();
      var completed = 0;
      
      // Process files asynchronously
      await _fileService.processFilesAsync(
        sourcePaths: sourcePaths,
        targetDir: _currentPath,
        isMove: _isItemCut,
        onProgress: (progress, total) {
          if (mounted) {
            setState(() {
              completed = progress;
            });
          }
        },
      );
      
      // Clear clipboard after cut-paste
      if (_isItemCut) {
        setState(() {
          _clipboardItems = null;
        });
      }
      
      // Dismiss progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success notification
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: _isItemCut 
              ? 'Moved $completed items' 
              : 'Copied $completed items',
          type: NotificationType.success,
        );
      }
      
      // Refresh directory contents
      _loadDirectory(_currentPath);
      
    } catch (e) {
      // Dismiss progress dialog if it's still showing
      if (mounted) {
        Navigator.of(context).pop();
        NotificationService.showNotification(
          context,
          message: 'Error during operation: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _showPropertiesDialog(FileItem item) async {
    final File file = File(item.path);
    final Directory dir = Directory(item.path);
    final bool isDirectory = item.type == FileItemType.directory;
    
    // Check if this is a mount point
    bool isMountPoint = false;
    if (isDirectory) {
      isMountPoint = await _isDirectoryMountPoint(item.path);
    }
    
    // Get file or directory stats
    final FileStat stat = isDirectory 
        ? dir.statSync() 
        : file.statSync();
    
    // For directories, calculate the number of items
    int itemCount = 0;
    int totalSize = 0;
    
    if (isDirectory) {
      try {
        final List<FileSystemEntity> entities = dir.listSync();
        itemCount = entities.length;
        
        // Calculate total size for directory contents (first level only)
        for (final entity in entities) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        }
      } catch (e) {
        // Handle permission issues silently
      }
    }
    
    // Helper function to format size
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    
    // Check if the widget is still mounted before using context
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDirectory ? (isMountPoint ? Icons.usb : Icons.folder) : Icons.insert_drive_file,
              color: isDirectory ? (isMountPoint ? Colors.amber : Colors.blue) : Colors.blueGrey,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Properties: ${item.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Path'),
                subtitle: Text(item.path, style: TextStyle(fontSize: 13)),
                dense: true,
              ),
              ListTile(
                title: Text('Type'),
                subtitle: Text(isDirectory ? (isMountPoint ? 'Mount Point' : 'Directory') : 'File - ${item.fileExtension}', style: TextStyle(fontSize: 13)),
                dense: true,
              ),
              ListTile(
                title: Text('Size'),
                subtitle: Text(
                  isDirectory
                      ? '$itemCount items, ${totalSize > 0 ? formatBytes(totalSize) : "Calculating..."}'
                      : item.formattedSize,
                  style: TextStyle(fontSize: 13)
                ),
                dense: true,
              ),
              ListTile(
                title: Text('Modified'),
                subtitle: Text(item.formattedModifiedTime, style: TextStyle(fontSize: 13)),
                dense: true,
              ),
              ListTile(
                title: Text('Permissions'),
                subtitle: Text(stat.modeString().substring(1), style: TextStyle(fontSize: 13)),
                dense: true,
              ),
              if (isMountPoint)
                ListTile(
                  title: Text('Mount Status'),
                  subtitle: Text('Mounted', style: TextStyle(fontSize: 13, color: Colors.green)),
                  dense: true,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          if (isMountPoint)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showUnmountConfirmation(item);
              },
              icon: Icon(Icons.eject),
              label: Text('Unmount'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // Add method to show quick look for selected file item
  void _showQuickLook(FileItem item) {
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    final quickLookService = QuickLookService(
      context: context,
      previewPanelService: previewPanelService,
    );
    quickLookService.showQuickLook(item);
  }

  // Handle key events for the file explorer
  void _handleKeyEvent(KeyEvent event) {
    // Debug log for keyboard events
    _logger.info('Key event: ${event.logicalKey}, Alt pressed: ${HardwareKeyboard.instance.isAltPressed}');

    // If we're searching, don't interfere with normal text input
    if (_isSearchActive && _searchFocusNode.hasFocus) {
      return;
    }

    // Handle quick look with space bar
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.space && 
        _selectedItemsPaths.isNotEmpty) {
      // Get the first selected item for quick look
      final selectedPath = _selectedItemsPaths.first;
      final selectedItem = _items.firstWhere(
        (item) => item.path == selectedPath,
        orElse: () => FileItem(
          path: '',
          name: '',
          type: FileItemType.unknown,
        ),
      );
      
      if (selectedItem.type != FileItemType.unknown) {
        _showQuickLook(selectedItem);
      }
    }

    // Handle search dialog with Alt+S
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.keyS && 
        HardwareKeyboard.instance.isAltPressed) {
      _logger.info('Alt+S detected, showing search dialog');
      _showSearchDialog();
    }

    // Navigation with arrow keys
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace || 
          (event.logicalKey == LogicalKeyboardKey.arrowUp && HardwareKeyboard.instance.isAltPressed)) {
        // Navigate up one directory
        final currentDir = Directory(_currentPath);
        final parentDir = currentDir.parent.path;
        if (parentDir != _currentPath) {
          _navigateToDirectory(parentDir);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        // Delete selected items
        if (_selectedItemsPaths.isNotEmpty) {
          _deleteSelectedItems();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        // Refresh directory
        _loadDirectory(_currentPath);
      } else if (event.logicalKey == LogicalKeyboardKey.keyC && HardwareKeyboard.instance.isControlPressed) {
        // Copy selected items
        _copySelectedItems();
      } else if (event.logicalKey == LogicalKeyboardKey.keyX && HardwareKeyboard.instance.isControlPressed) {
        // Cut selected items
        _cutSelectedItems();
      } else if (event.logicalKey == LogicalKeyboardKey.keyV && HardwareKeyboard.instance.isControlPressed) {
        // Paste items
        _pasteItemsToCurrentDirectory();
      } else if (event.logicalKey == LogicalKeyboardKey.keyA && HardwareKeyboard.instance.isControlPressed) {
        // Select all items
        setState(() {
          _selectedItemsPaths = _items.map((item) => item.path).toSet();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.keyH && 
                 HardwareKeyboard.instance.isControlPressed && 
                 HardwareKeyboard.instance.isShiftPressed) {
        // Toggle tab bar visibility
        final tabManager = Provider.of<TabManagerService>(context, listen: false);
        tabManager.setShowTabBar(!tabManager.showTabBar);
      } else if (event.logicalKey == LogicalKeyboardKey.keyH && HardwareKeyboard.instance.isControlPressed) {
        // Toggle hidden files visibility
        setState(() {
          _showHiddenFiles = !_showHiddenFiles;
        });
        _loadDirectory(_currentPath); // Reload directory with new visibility setting
      }
    }
  }

  void _showSearchDialog() async {
    final fileService = Provider.of<FileService>(context, listen: false);
    fileService.setCurrentDirectory(_currentPath);
    
    final result = await showDialog<FileItem>(
      context: context,
      builder: (context) => SearchDialog(
        currentDirectory: _currentPath,
        fileService: _fileService,
        onFileSelected: (path) {
          // No need to handle navigation here, we'll do it after the dialog closes
        },
      ),
    );
    
    if (result != null) {
      if (result.type == FileItemType.directory) {
        // Navigate to the directory
        _navigateToDirectory(result.path);
      } else {
        // Open the file with default application
        final fileAssociationService = Provider.of<FileAssociationService>(context, listen: false);
        final defaultApp = fileAssociationService.getDefaultAppForFile(result.path);
        
        if (defaultApp != null) {
          final appService = Provider.of<AppService>(context, listen: false);
          await appService.openFileWithApp(result.path, defaultApp);
        } else {
          // If no default app is set, show the app selection dialog
          _showAppSelectionDialog(result);
        }
      }
    }
  }

  // Check if a directory is a mount point
  Future<bool> _isDirectoryMountPoint(String path) async {
    try {
      // Use mount command to list mounted file systems
      final result = await Process.run('mount', []);
      if (result.exitCode != 0) return false;
      
      // Parse the mount output
      final List<String> mountOutput = result.stdout.toString().split('\n');
      
      // Check if the path is in the mount list
      for (final line in mountOutput) {
        if (line.contains(' on $path ')) {
          return true;
        }
      }
      
      // Also check with UsbDriveService
      final drives = await _usbDriveService.getMountedUsbDrives();
      return drives.any((drive) => drive.mountPoint == path);
    } catch (e) {
      // If there's an error, assume it's not a mount point
      return false;
    }
  }

  // Build breadcrumb navigation widget
  Widget _buildBreadcrumbNavigator() {
    // Split the path into segments
    final List<String> pathSegments = [];
    
    // Always start with root
    String currentBuiltPath = '';
    
    // Handle root directory
    if (_currentPath == '/') {
      pathSegments.add('/');
    } else {
      // Split the path and build segments with full paths
      final parts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
      
      // Add root
      pathSegments.add('/');
      currentBuiltPath = '/';
      
      // Add each subsequent directory
      for (int i = 0; i < parts.length; i++) {
        currentBuiltPath = '$currentBuiltPath${parts[i]}/';
        pathSegments.add(currentBuiltPath);
      }
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < pathSegments.length; i++)
            Row(
              children: [
                // No separator before root
                if (i > 0)
                  const Text(' / ', style: TextStyle(color: Colors.grey)),
                
                InkWell(
                  onTap: () => _navigateToDirectory(pathSegments[i]),
                  child: Text(
                    i == 0 
                        ? 'Root'  // Root directory
                        : p.basename(pathSegments[i].substring(0, pathSegments[i].length - 1)),  // Remove trailing slash
                    style: TextStyle(
                      color: i == pathSegments.length - 1
                          ? Theme.of(context).primaryColor  // Current directory
                          : null,
                      fontWeight: i == pathSegments.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Show app options menu
  void _showOptionsMenu(BuildContext context) {
    final viewModeService = Provider.of<ViewModeService>(context, listen: false);
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    final iconSizeService = Provider.of<IconSizeService>(context, listen: false);
    final statusBarService = Provider.of<StatusBarService>(context, listen: false);
    final appService = Provider.of<AppService>(context, listen: false);
    
    // Calculate position relative to the action bar
    // This positions it just below the options button
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size(0, 0);
    
    // Position the menu right-aligned with the options button and just below the action bar
    final RelativeRect position = RelativeRect.fromLTRB(
      size.width - 250, // Right-align, 250px width for menu (wider to accommodate slider)
      40, // Just below the action bar (which is about 40px tall)
      0,  // No right padding
      0   // No bottom padding
    );
    
    // Create a StatefulBuilder for the slider
    StatefulBuilder statefulBuilder = StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        // Calculate a normalized value for the slider (0.0 to 1.0)
        double sliderValue = viewModeService.isGrid 
            ? (iconSizeService.gridUIScale - IconSizeService.minGridUIScale) / 
              (IconSizeService.maxGridUIScale - IconSizeService.minGridUIScale)
            : (iconSizeService.listUIScale - IconSizeService.minListUIScale) / 
              (IconSizeService.maxListUIScale - IconSizeService.minListUIScale);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(
            width: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Standard menu items
                PopupMenuItem<String>(
                  value: 'view_mode',
                  child: Row(
                    children: [
                      Icon(Icons.view_list, size: 16),
                      SizedBox(width: 8),
                      Text('View Mode'),
                    ],
                  ),
                ),
                
                // Toggle status bar
                PopupMenuItem<String>(
                  value: 'status_bar',
                  child: Row(
                    children: [
                      Icon(statusBarService.showStatusBar ? Icons.visibility_off : Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text(statusBarService.showStatusBar ? 'Hide Status Bar' : 'Show Status Bar'),
                    ],
                  ),
                ),
                
                // Toggle preview panel
                PopupMenuItem<String>(
                  value: 'preview_panel',
                  child: Row(
                    children: [
                      Icon(previewPanelService.showPreviewPanel ? Icons.info : Icons.info_outline, size: 16),
                      SizedBox(width: 8),
                      Text(previewPanelService.showPreviewPanel ? 'Hide Preview Panel' : 'Show Preview Panel'),
                    ],
                  ),
                ),
                
                // Open in Terminal option
                PopupMenuItem<String>(
                  value: 'terminal',
                  child: Row(
                    children: [
                      Icon(Icons.terminal, size: 16),
                      SizedBox(width: 8),
                      Text('Open in Terminal'),
                    ],
                  ),
                ),
                
                // Tags View option
                PopupMenuItem<String>(
                  value: 'tags_view',
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, size: 16),
                      SizedBox(width: 8),
                      Text('Manage Tags'),
                    ],
                  ),
                ),
                
                const PopupMenuDivider(),
                
                // File associations
                PopupMenuItem<String>(
                  value: 'file_associations',
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16),
                      SizedBox(width: 8),
                      Text('File Associations'),
                    ],
                  ),
                ),
                
                // Refresh application list
                PopupMenuItem<String>(
                  value: 'refresh_apps',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 16),
                      SizedBox(width: 8),
                      Text('Refresh App List'),
                    ],
                  ),
                ),

                // Keyboard shortcuts
                PopupMenuItem<String>(
                  value: 'keyboard_shortcuts',
                  child: Row(
                    children: [
                      Icon(Icons.keyboard, size: 16),
                      SizedBox(width: 8),
                      Text('Keyboard Shortcuts'),
                    ],
                  ),
                ),
                
                // Divider before icon size slider
                const PopupMenuDivider(),
                
                // Icon size slider section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.photo_size_select_small, size: 18),
                      Expanded(
                        child: Slider(
                          value: sliderValue,
                          onChanged: (newValue) {
                            setState(() {
                              if (viewModeService.isGrid) {
                                // Map the 0-1 value to the grid UI scale range
                                double newScale = IconSizeService.minGridUIScale + 
                                    newValue * (IconSizeService.maxGridUIScale - IconSizeService.minGridUIScale);
                                // Calculate how many steps to increase/decrease
                                double steps = (newScale - iconSizeService.gridUIScale) / IconSizeService.gridUIScaleStep;
                                if (steps > 0) {
                                  for (int i = 0; i < steps.round(); i++) {
                                    iconSizeService.increaseGridIconSize();
                                  }
                                } else if (steps < 0) {
                                  for (int i = 0; i < steps.abs().round(); i++) {
                                    iconSizeService.decreaseGridIconSize();
                                  }
                                }
                              } else {
                                // Map the 0-1 value to the list UI scale range
                                double newScale = IconSizeService.minListUIScale + 
                                    newValue * (IconSizeService.maxListUIScale - IconSizeService.minListUIScale);
                                // Calculate how many steps to increase/decrease
                                double steps = (newScale - iconSizeService.listUIScale) / IconSizeService.listUIScaleStep;
                                if (steps > 0) {
                                  for (int i = 0; i < steps.round(); i++) {
                                    iconSizeService.increaseListIconSize();
                                  }
                                } else if (steps < 0) {
                                  for (int i = 0; i < steps.abs().round(); i++) {
                                    iconSizeService.decreaseListIconSize();
                                  }
                                }
                              }
                            });
                          },
                        ),
                      ),
                      Icon(Icons.photo_size_select_large, size: 18),
                    ],
                  ),
                ),
                // Label for the slider
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Icon Size',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    // Show the custom menu
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              top: position.top,
              right: 0,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF2D2E30)
                    : Colors.white,
                child: statefulBuilder,
              ),
            ),
          ],
        );
      },
    ).then((value) {
      // Handle selection outside of slider
      if (value != null && mounted) {
        switch (value) {
          case 'view_mode':
            _showViewModeSubmenu(context, size);
            break;
          case 'status_bar':
            statusBarService.toggleStatusBar();
            break;
          case 'preview_panel':
            previewPanelService.togglePreviewPanel();
            break;
          case 'terminal':
            _openDirectoryInTerminal();
            break;
          case 'tags_view':
            Navigator.pushNamed(context, '/tags');
            break;
          case 'file_associations':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FileAssociationsScreen()),
            );
            break;
          case 'refresh_apps':
            appService.refreshApps();
            break;
          case 'keyboard_shortcuts':
            showDialog(
              context: context,
              builder: (context) => const KeyboardShortcutsDialog(),
            );
            break;
        }
      }
    });
  }
  
  // Show view mode submenu
  void _showViewModeSubmenu(BuildContext context, Size size) {
    final viewModeService = Provider.of<ViewModeService>(context, listen: false);
    
    Future.delayed(const Duration(milliseconds: 10), () {
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          size.width - 180, // Right-align, slightly offset from main menu
          70, // Below the main menu item
          0,  // No right padding
          0   // No bottom padding
        ),
        items: <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'list',
            child: Row(
              children: [
                Icon(Icons.view_list),
                SizedBox(width: 8),
                Text('List View'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'grid',
            child: Row(
              children: [
                Icon(Icons.grid_view),
                SizedBox(width: 8),
                Text('Grid View'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.table_rows),
                SizedBox(width: 8),
                Text('Details View'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'column',
            child: Row(
              children: [
                Icon(Icons.view_column),
                SizedBox(width: 8),
                Text('Column View'),
              ],
            ),
          ),
        ],
      ).then((value) {
        if (value == null || !mounted) return;
        
        switch (value) {
          case 'list':
            viewModeService.setViewMode(ViewMode.list);
            break;
          case 'grid':
            viewModeService.setViewMode(ViewMode.grid);
            break;
          case 'details':
            viewModeService.setViewMode(ViewMode.split);
            break;
          case 'column':
            viewModeService.setViewMode(ViewMode.column);
            break;
        }
      });
    });
  }
  
  // Function to delete selected items
  void _deleteSelectedItems() async {
    if (_selectedItemsPaths.isEmpty) return;
    
    List<FileItem> itemsToDelete = _items.where(
      (item) => _selectedItemsPaths.contains(item.path)
    ).toList();
    
    // Show confirmation dialog
    final bool confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${itemsToDelete.length} ${itemsToDelete.length == 1 ? 'Item' : 'Items'}'),
        content: Text('Are you sure you want to delete the selected items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      try {
        // Show progress for multiple items
        if (itemsToDelete.length > 1) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: Text("Deleting Files"),
                  content: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(width: 16),
                      Text("Deleting ${itemsToDelete.length} items..."),
                    ],
                  ),
                );
              },
            );
          }
        }
        
        int successCount = 0;
        List<String> errors = [];
        
        // Delete each item
        for (final item in itemsToDelete) {
          try {
            await _fileService.deleteFileOrDirectory(item.path);
            successCount++;
          } catch (e) {
            errors.add("${item.name}: $e");
          }
        }
        
        // Dismiss progress dialog if it was shown
        if (itemsToDelete.length > 1 && mounted) {
          Navigator.pop(context);
        }
        
        // Refresh directory contents
        _loadDirectory(_currentPath);
        
        // Show result notification
        if (mounted) {
          if (errors.isEmpty) {
            NotificationService.showNotification(
              context,
              message: "Deleted $successCount ${successCount == 1 ? "item" : "items"}",
              type: NotificationType.success,
            );
          } else {
            NotificationService.showNotification(
              context,
              message: "Completed with ${errors.length} errors",
              type: NotificationType.warning,
            );
            
            // Show detailed error dialog for multiple errors
            if (errors.length > 1 && mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Delete Errors"),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 200,
                    child: ListView.builder(
                      itemCount: errors.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text(errors[index], 
                              style: TextStyle(fontSize: 14)),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close"),
                    ),
                  ],
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: "Error: $e",
            type: NotificationType.error,
          );
        }
  
    }
    }
  }

  // Copy selected items to clipboard
  void _copySelectedItems() {
    if (_selectedItemsPaths.isEmpty) return;
    
    final List<FileItem> selectedItems = _items
        .where((item) => _selectedItemsPaths.contains(item.path))
        .toList();
    
    setState(() {
      _clipboardItems = selectedItems;
      _isItemCut = false;
    });
    
    NotificationService.showNotification(
      context,
      message: 'Copied ${selectedItems.length} ${selectedItems.length == 1 ? 'item' : 'items'} to clipboard',
      type: NotificationType.info,
    );
  }
  
  void _cutSelectedItems() {
    if (_selectedItemsPaths.isEmpty) return;
    
    final List<FileItem> selectedItems = _items
        .where((item) => _selectedItemsPaths.contains(item.path))
        .toList();
    
    setState(() {
      _clipboardItems = selectedItems;
      _isItemCut = true;
    });
    
    NotificationService.showNotification(
      context,
      message: 'Cut ${selectedItems.length} ${selectedItems.length == 1 ? 'item' : 'items'} to clipboard',
      type: NotificationType.info,
    );
  }

  // Check if a file or directory exists at the given path
  Future<bool> _fileExists(String path) async {
    try {
      return await File(path).exists() || await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }

  // Show confirmation dialog for unmounting drives
  Future<void> _showUnmountConfirmation(FileItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unmount Drive'),
        content: Text('Are you sure you want to unmount "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unmount'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _usbDriveService.unmountDrive(item.path);
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Unmounted drive: ${item.name}',
            type: NotificationType.success,
          );
        }
        // Navigate to parent directory after unmounting
        final currentDir = Directory(_currentPath);
        final parentDir = currentDir.parent.path;
        _navigateToDirectory(parentDir);
      } catch (e) {
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Error unmounting drive: $e',
            type: NotificationType.error,
          );
        }
      }
    }
  }

  // Open in terminal for current directory
  void _openDirectoryInTerminal() {
    // Create a temporary FileItem for the current directory
    final currentDirItem = FileItem(
      path: _currentPath,
      name: p.basename(_currentPath),
      type: FileItemType.directory,
    );
    
    _openInTerminal(currentDirItem);
  }

  // Show dialog to choose an application to open a file
  Future<void> _showOpenWithDialog(FileItem item) async {
    try {
      // Extract filename from the path
      final fileName = p.basename(item.path);
      
      // Show app selection dialog
      showDialog(
        context: context,
        builder: (context) => AppSelectionDialog(
          filePath: item.path,
          fileName: fileName,
        ),
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to show open with dialog: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  // Open a terminal in the specified directory
  void _openInTerminal(FileItem item) {
    if (item.type != FileItemType.directory) return;
    
    try {
      _logger.info('Attempting to open terminal in directory: ${item.path}');
      
      // First try warp-terminal with a script-based approach
      Process.run('which', ['warp-terminal']).then((result) {
        final String warpPath = result.stdout.toString().trim();
        if (warpPath.isNotEmpty) {
          _logger.info('Found warp-terminal at: $warpPath');
          
          // Try the shell script approach first
          _tryWarpTerminalWithScript(item, warpPath).catchError((e) {
            _logger.warning('Script approach failed: $e. Trying with environment variables...');
            
            // Fallback to environment variable approach if script fails
            return _tryWarpTerminalWithEnv(item, warpPath);
          }).catchError((e) {
            _logger.severe('All warp-terminal approaches failed: $e');
            return _tryFallbackTerminals(item).then((process) => process);
          });
        } else {
          // Warp terminal not found, try others
          _tryFallbackTerminals(item);
        }
      }).catchError((e) {
        _logger.severe('Error checking for warp-terminal: $e');
        _tryFallbackTerminals(item);
      });
    } catch (e) {
      _logger.severe('Error in _openInTerminal: $e');
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to open terminal: $e',
          type: NotificationType.error,
        );
      }
    }
  }
  
  // Try launching warp-terminal with a shell script
  Future<Process> _tryWarpTerminalWithScript(FileItem item, String warpPath) {
    // Create a temporary script to open warp in the correct directory
    final tempDir = Directory.systemTemp;
    final scriptFile = File('${tempDir.path}/open_warp_${DateTime.now().millisecondsSinceEpoch}.sh');
    
    // Create script content to change directory and launch warp
    final scriptContent = '''#!/bin/bash
cd "${item.path}"
exec $warpPath
exit
''';
    
    // Write and make executable
    scriptFile.writeAsStringSync(scriptContent);
    Process.runSync('chmod', ['+x', scriptFile.path]);
    
    _logger.info('Created script at ${scriptFile.path} with content:\n$scriptContent');
    
    // Run the script
    return Process.start('bash', [scriptFile.path]).then((process) {
      _logger.info('Warp terminal script started with PID: ${process.pid}');
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Terminal opened in ${p.basename(item.path)}',
          type: NotificationType.success,
        );
      }
      
      // Clean up the script file after a delay
      Future.delayed(Duration(seconds: 5), () {
        try {
          if (scriptFile.existsSync()) {
            scriptFile.deleteSync();
            _logger.info('Deleted temporary script');
          }
        } catch (e) {
          _logger.warning('Failed to delete temporary script: $e');
        }
      });
      
      return process;
    });
  }
  
  // Try launching warp-terminal with environment variables
  Future<Process> _tryWarpTerminalWithEnv(FileItem item, String warpPath) {
    _logger.info('Trying with environment variables approach');
    
    // Set up environment variables including PWD
    final Map<String, String> environment = Map.from(Platform.environment);
    environment['PWD'] = item.path; // Setting PWD to target directory
    
    // Create a bash command that sets PWD and launches warp
    // ignore: unnecessary_brace_in_string_interps
    final bashCommand = 'cd "${item.path}" && $warpPath';
    
    // Launch bash with the command
    return Process.start('bash', ['-c', bashCommand], environment: environment).then((process) {
      _logger.info('Warp terminal with env vars started with PID: ${process.pid}');
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Terminal opened in ${p.basename(item.path)}',
          type: NotificationType.success,
        );
      }
      
      return process;
    });
  }
  
  // Try other terminal emulators as fallback
  Future<Process> _tryFallbackTerminals(FileItem item) {
    // Create a completer to manage the async process
    final completer = Completer<Process>();
    
    // Common terminal emulators to check (excluding warp which we already tried)
    final List<String> fallbackTerminals = [
      'gnome-terminal',
      'konsole',
      'xfce4-terminal',
      'terminator',
      'tilix',
      'xterm',
      'urxvt',
      'alacritty',
      'kitty',
    ];
    
    // Find the first available terminal
    Process.run('which', fallbackTerminals).then((result) {
      final String output = result.stdout.toString().trim();
      
      if (output.isNotEmpty) {
        final String terminal = output.split('\n').first;
        final List<String> command = [];
        
        // Customize command based on terminal
        if (terminal.contains('gnome-terminal')) {
          command.addAll([terminal, '--working-directory=${item.path}']);
        } else if (terminal.contains('konsole')) {
          command.addAll([terminal, '--workdir', item.path]);
        } else if (terminal.contains('xfce4-terminal')) {
          command.addAll([terminal, '--working-directory=${item.path}']);
        } else if (terminal.contains('terminator')) {
          command.addAll([terminal, '--working-directory=${item.path}']);
        } else if (terminal.contains('tilix')) {
          command.addAll([terminal, '--working-directory=${item.path}']);
        } else if (terminal.contains('alacritty')) {
          command.addAll([terminal, '--working-directory', item.path]);
        } else if (terminal.contains('kitty')) {
          command.addAll([terminal, '--directory', item.path]);
        } else {
          // For other terminals, fallback to cd command
          command.addAll([terminal, '-e', 'cd "${item.path}" && bash']);
        }
        
        _logger.info('Opening fallback terminal with command: $command');
        Process.start(command[0], command.sublist(1)).then((process) {
          // Log success
          _logger.info('Fallback terminal process started with PID: ${process.pid}');
          
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: 'Terminal opened in ${p.basename(item.path)}',
              type: NotificationType.success,
            );
          }
          completer.complete(process);
        }).catchError((e) {
          // Log detailed error
          _logger.severe('Error starting fallback terminal process: $e');
          if (mounted) {
            NotificationService.showNotification(
              context,
              message: 'Failed to start terminal: $e',
              type: NotificationType.error,
            );
          }
          completer.completeError(e);
        });
      } else {
        // No terminals found
        final error = 'No available terminal emulators found';
        _logger.warning(error);
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: error,
            type: NotificationType.error,
          );
        }
        completer.completeError(Exception(error));
      }
    }).catchError((e) {
      // Error checking for terminals
      _logger.severe('Error checking for terminal emulators: $e');
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to find terminal: $e',
          type: NotificationType.error,
        );
      }
      completer.completeError(e);
    });
    
    return completer.future;
  }

  // Show context menu for empty area
  void _showEmptyAreaContextMenu(Offset position) async {
    // Clear selection
    setState(() {
      _selectedItemsPaths = {};
    });
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // Create a relative rectangle for positioning the menu
    final RelativeRect menuPosition = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
    );
    
    // Add mounted check
    if (!mounted) return;
    
    // Check if clipboard has items 
    final bool hasClipboardItems = _clipboardItems != null && _clipboardItems!.isNotEmpty;
    // Check if there are items that can be selected
    final bool hasItemsToSelect = _items.isNotEmpty;
    
    // Create menu items
    final menuItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'new_folder',
        child: Row(
          children: [
            Icon(Icons.create_new_folder, size: 16),
            SizedBox(width: 8),
            Text('New Folder'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'new_file',
        child: Row(
          children: [
            Icon(Icons.note_add, size: 16),
            SizedBox(width: 8),
            Text('New File'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'paste',
        enabled: hasClipboardItems,
        child: Row(
          children: [
            Icon(Icons.paste, size: 16, color: hasClipboardItems ? null : Colors.grey),
            SizedBox(width: 8),
            Text('Paste', style: TextStyle(color: hasClipboardItems ? null : Colors.grey)),
          ],
        ),
      ),
      const PopupMenuDivider(),
      if (hasItemsToSelect) ...[
        PopupMenuItem<String>(
          value: 'select_all',
          child: Row(
            children: [
              Icon(Icons.select_all, size: 16),
              SizedBox(width: 8),
              Text('Select All'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_by',
          child: Row(
            children: [
              Icon(Icons.sort, size: 16),
              SizedBox(width: 8),
              Text('Sort By'),
            ],
          ),
        ),
      ],
      PopupMenuItem<String>(
        value: 'terminal',
        child: Row(
          children: [
            Icon(Icons.terminal, size: 16),
            SizedBox(width: 8),
            Text('Open in Terminal'),
          ],
        ),
      ),
    ];
    
    // Show context menu
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF2D2E30)
          : Colors.white,
      items: menuItems,
    );
    
    // Process the selected menu option
    if (result == null || !mounted) return;
    
    // Handle menu selection
    switch (result) {
      case 'new_folder':
        _handleCreateNewFolder();
        break;
      case 'new_file':
        _handleCreateNewFile();
        break;
      case 'paste':
        if (hasClipboardItems) {
          _pasteFromSystemClipboard();
        }
        break;
      case 'select_all':
        if (hasItemsToSelect) {
          _selectAllItems();
        }
        break;
      case 'sort_by':
        if (hasItemsToSelect) {
          _handleSortByOptions(position);
        }
        break;
      case 'terminal':
        _openDirectoryInTerminal();
        break;
    }
  }
  
  // Handle creating a new folder
  void _handleCreateNewFolder() {
    _showCreateDialog(true);
  }
  
  // Handle creating a new file
  void _handleCreateNewFile() {
    _showCreateDialog(false);
  }
  
  // Select all items in the current directory
  void _selectAllItems() {
    setState(() {
      // Get paths of all visible items
      _selectedItemsPaths = _items.map((item) => item.path).toSet();
    });
    
    // Show notification
    if (mounted) {
      NotificationService.showNotification(
        context,
        message: 'Selected ${_selectedItemsPaths.length} items',
        type: NotificationType.info,
      );
    }
  }
  
  // Handle showing sort options
  void _handleSortByOptions(Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    // Create a relative rectangle for positioning the menu
    final RelativeRect menuPosition = RelativeRect.fromRect(
      Rect.fromPoints(position.translate(100, 0), position.translate(100, 0)),
      Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
    );
    
    showMenu<String>(
      context: context,
      position: menuPosition,
      color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF2D2E30)
          : Colors.white,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'name_asc',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 16),
              SizedBox(width: 8),
              Text('Name (A to Z)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'name_desc',
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, textDirection: TextDirection.rtl, size: 16),
              SizedBox(width: 8),
              Text('Name (Z to A)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'date_newest',
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16),
              SizedBox(width: 8),
              Text('Date Modified (Newest First)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'date_oldest',
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16),
              SizedBox(width: 8),
              Text('Date Modified (Oldest First)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'size_largest',
          child: Row(
            children: [
              Icon(Icons.format_size, size: 16),
              SizedBox(width: 8),
              Text('Size (Largest First)'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'size_smallest',
          child: Row(
            children: [
              Icon(Icons.format_size),
              SizedBox(width: 8),
              Text('Size (Smallest First)'),
            ],
          ),
        ),
      ],
    ).then((result) {
      if (result == null || !mounted) return;
      
      // Sort items based on selection
      setState(() {
        switch (result) {
          case 'name_asc':
            _sortItems((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case 'name_desc':
            _sortItems((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
            break;
          case 'date_newest':
            _sortItems((a, b) => (b.modifiedTime ?? DateTime(1970))
                .compareTo(a.modifiedTime ?? DateTime(1970)));
            break;
          case 'date_oldest':
            _sortItems((a, b) => (a.modifiedTime ?? DateTime(1970))
                .compareTo(b.modifiedTime ?? DateTime(1970)));
            break;
          case 'size_largest':
            _sortItems((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
            break;
          case 'size_smallest':
            _sortItems((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
            break;
        }
      });
      
      // Show notification
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Sorted files by ${_getSortByName(result)}',
          type: NotificationType.info,
        );
      }
    });
  }
  
  // Sort items with directories always first
  void _sortItems(int Function(FileItem a, FileItem b) compareFunc) {
    _items.sort((a, b) {
      // Always keep directories first
      if (a.type == FileItemType.directory && b.type != FileItemType.directory) {
        return -1;
      }
      if (a.type != FileItemType.directory && b.type == FileItemType.directory) {
        return 1;
      }
      
      // Then apply the specific sort function
      return compareFunc(a, b);
    });
  }
  
  // Get human-readable name for sort option
  String _getSortByName(String sortOption) {
    switch (sortOption) {
      case 'name_asc': return 'name (A to Z)';
      case 'name_desc': return 'name (Z to A)';
      case 'date_newest': return 'date (newest first)';
      case 'date_oldest': return 'date (oldest first)';
      case 'size_largest': return 'size (largest first)';
      case 'size_smallest': return 'size (smallest first)';
      default: return sortOption;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManagerService>(context);
    final currentTab = tabManager.currentTab;
    final previewPanelService = Provider.of<PreviewPanelService>(context);

    // Handle animations
    if (previewPanelService.showPreviewPanel && _previewPanelAnimation.isDismissed) {
      _previewPanelAnimation.forward();
    } else if (!previewPanelService.showPreviewPanel && _previewPanelAnimation.isCompleted) {
      _previewPanelAnimation.reverse();
    }
    
    if (_showBookmarkSidebar && _bookmarkSidebarAnimation.isDismissed) {
      _bookmarkSidebarAnimation.forward();
    } else if (!_showBookmarkSidebar && _bookmarkSidebarAnimation.isCompleted) {
      _bookmarkSidebarAnimation.reverse();
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _logger.info('Focus node received key event: ${event.logicalKey}');
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF202124) // Dark mode background
                : const Color(0xFFE8F0FE), // Very light blue background
          ),
          child: Column(
            children: [
              if (tabManager.showTabBar) const FileExplorerTabBar(),
              _buildAppBar(context),
              Expanded(
                child: Row(
                  children: [
                    if (_showBookmarkSidebar)
                      AnimatedBuilder(
                        animation: _bookmarkSidebarAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: _bookmarkSidebarAnimation.value * 200,
                            child: BookmarkSidebar(
                              onNavigate: _navigateToDirectory,
                              currentPath: _currentPath,
                            ),
                          );
                        },
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: currentTab != null && currentTab.hasError
                                ? Center(child: Text(currentTab.errorMessage))
                                : _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : _buildFileView(),
                          ),
                        ],
                      ),
                    ),
                    if (previewPanelService.showPreviewPanel)
                      AnimatedBuilder(
                        animation: _previewPanelAnimation,
                        builder: (context, child) {
                          return SizedBox(
                            width: _previewPanelAnimation.value * 300,
                            child: PreviewPanel(
                              onNavigate: _navigateToDirectory,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (Provider.of<StatusBarService>(context).showStatusBar)
                StatusBar(
                  items: _items,
                  selectedItemsPaths: _selectedItemsPaths,
                  currentPath: _currentPath,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileView() {
    final viewModeService = Provider.of<ViewModeService>(context);
    final statusBarService = Provider.of<StatusBarService>(context);
    final iconSizeService = Provider.of<IconSizeService>(context);
    final previewPanelService = Provider.of<PreviewPanelService>(context);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  // Main content area with flexible width
                  Flexible(
                    flex: 1,
                    child: _buildMainContentArea(
                      viewModeService, 
                      iconSizeService, 
                      previewPanelService,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode 
              ? const Color(0xFF2C2C2C) // Dark mode toolbar color
              : const Color(0xFFF5F5F5), // Light mode toolbar color
          border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Application title
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    size: 18,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Linux File Manager',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Divider between title and navigation buttons
            Container(
              height: 24,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
            ),
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _navigationHistory.isEmpty ? null : _navigateBack,
              tooltip: 'Back',
              iconSize: 20,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: _forwardHistory.isEmpty ? null : _navigateForward,
              tooltip: 'Forward',
              iconSize: 20,
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _loadDirectory(_currentPath),
              tooltip: 'Refresh',
              iconSize: 20,
            ),
            // Home button
            IconButton(
              icon: Icon(Icons.home),
              onPressed: _initHomeDirectory,
              tooltip: 'Home Directory',
              iconSize: 20,
            ),
            // Breadcrumb navigation bar
            Expanded(
              child: Container(
                key: _breadcrumbKey,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: _buildBreadcrumbNavigator(),
              ),
            ),
            // Bookmark toggle
            IconButton(
              icon: Icon(_showBookmarkSidebar ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () {
                setState(() {
                  _showBookmarkSidebar = !_showBookmarkSidebar;
                });
              },
              tooltip: _showBookmarkSidebar ? 'Hide Bookmarks' : 'Show Bookmarks',
              iconSize: 20,
            ),
            // Preview panel toggle
            IconButton(
              icon: Icon(previewPanelService.showPreviewPanel ? Icons.info : Icons.info_outline),
              onPressed: () => previewPanelService.togglePreviewPanel(),
              tooltip: previewPanelService.showPreviewPanel ? 'Hide Preview' : 'Show Preview',
              iconSize: 20,
            ),
            // Tags button
            IconButton(
              icon: Icon(Icons.local_offer_outlined),
              onPressed: () => Navigator.pushNamed(context, '/tags').then((result) {
                if (result != null && result is Map<String, dynamic>) {
                  // Handle navigation or file opening from tags view
                  if (result['action'] == 'navigate') {
                    final path = result['path'] as String;
                    final parentDir = p.dirname(path);
                    _navigateToDirectory(parentDir);
                    
                    // Wait for directory to load, then select the file
                    Future.delayed(const Duration(milliseconds: 300), () {
                      setState(() {
                        _selectedItemsPaths = {path};
                      });
                    });
                  } else if (result['action'] == 'open') {
                    final path = result['path'] as String;
                    // Try to find the file item to open it
                    try {
                      final file = File(path);
                      if (file.existsSync()) {
                        final item = FileItem.fromFile(file);
                        _handleItemDoubleTap(item);
                      }
                    } catch (e) {
                      debugPrint('Error opening file from tags: $e');
                    }
                  }
                }
              }),
              tooltip: 'Manage Tags',
              iconSize: 20,
            ),
            // Settings/options menu
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () => _showOptionsMenu(context),
              tooltip: 'Options',
              iconSize: 20,
            ),
            // Window title action buttons
            IconButton(
              icon: Icon(Icons.remove, size: 18),
              onPressed: () => windowManager.minimize(),
              tooltip: 'Minimize',
              color: isDarkMode ? Colors.white70 : Colors.black54,
              constraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 28,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            IconButton(
              icon: Icon(
                _isMaximized ? Icons.filter_none : Icons.crop_square,
                size: 18,
              ),
              onPressed: () async {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              tooltip: _isMaximized ? 'Restore' : 'Maximize',
              color: isDarkMode ? Colors.white70 : Colors.black54,
              constraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 28,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18),
              onPressed: () => windowManager.close(),
              tooltip: 'Close',
              color: isDarkMode ? Colors.white70 : Colors.black54,
              constraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 28,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContentArea(
    ViewModeService viewModeService, 
    IconSizeService iconSizeService,
    PreviewPanelService previewPanelService,
  ) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error loading directory',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(_errorMessage),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDirectory(_currentPath),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_items.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque, // Important to detect gestures on the empty area
        onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(details.globalPosition),
        onTap: () => setState(() => _selectedItemsPaths = {}), // Clear selection on tap
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                color: Theme.of(context).disabledColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'This folder is empty',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // Display files according to the selected view mode
    switch (viewModeService.viewMode) {
      case ViewMode.list:
        return _buildListView(_items, iconSizeService);
      case ViewMode.grid:
        return _buildGridView(_items, iconSizeService);
      case ViewMode.split:
        return _buildDetailsView(_items, iconSizeService);
      case ViewMode.column:
        return ColumnViewWidget(
          currentPath: _currentPath,
          items: _items,
          onNavigate: _navigateToDirectory,
          onItemTap: _selectItem,
          onItemDoubleTap: _handleItemDoubleTap,
          onItemLongPress: (item) => _showContextMenu(item, Offset.zero),
          onItemRightClick: _showContextMenu,
          selectedItemsPaths: _selectedItemsPaths,
          onEmptyAreaTap: () => setState(() => _selectedItemsPaths = {}),
          onEmptyAreaRightClick: _showEmptyAreaContextMenu,
        );
    }
  }

  // Implement the view builders
  Widget _buildListView(List<FileItem> items, IconSizeService iconSizeService) {
    return GestureDetector(
      onTap: () => setState(() => _selectedItemsPaths = {}),
      onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(details.globalPosition),
      onPanStart: (details) {
        setState(() {
          _dragStartPosition = details.localPosition;
          _dragEndPosition = details.localPosition;
          _mightStartDragging = true;
          _itemPositions.clear();
        });
      },
      onPanUpdate: (details) {
        if (_mightStartDragging) {
          setState(() {
            _dragEndPosition = details.localPosition;
          });
          _updateSelectionRectangle();
        }
      },
      onPanEnd: (details) {
        setState(() {
          _mightStartDragging = false;
        });
      },
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedItemsPaths.contains(item.path);
          
          // Get all selected items
          final selectedItems = _selectedItemsPaths.isNotEmpty
              ? items.where((i) => _selectedItemsPaths.contains(i.path)).toList()
              : null;
          
          return Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  final RenderBox? box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final Offset position = box.localToGlobal(Offset.zero);
                    final Size size = box.size;
                    _itemPositions[item.path] = Rect.fromLTWH(
                      position.dx,
                      position.dy,
                      size.width,
                      size.height,
                    );
                  }
                }
              });
              
              Widget itemWidget = DraggableFileItem(
                key: ValueKey(item.path),
                item: item,
                isSelected: isSelected,
                isGridMode: false,
                selectedItems: selectedItems,
                onTap: (item, isCtrlPressed) => _selectItem(item, isCtrlPressed),
                onDoubleTap: () => _handleItemDoubleTap(item),
                onLongPress: (item) => _showContextMenu(item, Offset.zero),
                onRightClick: _showContextMenu,
              );
              
              // Wrap directory items with FolderDropTarget
              if (item.type == FileItemType.directory) {
                itemWidget = FolderDropTarget(
                  folder: item,
                  onNavigateToDirectory: _navigateToDirectory,
                  onDropSuccessful: () {
                    // Refresh the directory after a successful drop
                    _loadDirectory(_currentPath);
                  },
                  child: itemWidget,
                );
              }
              
              return itemWidget;
            }
          );
        },
      ),
    );
  }
  
  Widget _buildGridView(List<FileItem> items, IconSizeService iconSizeService) {
    return GestureDetector(
      onTap: () => setState(() => _selectedItemsPaths = {}),
      onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(details.globalPosition),
      onPanStart: (details) {
        setState(() {
          _dragStartPosition = details.localPosition;
          _dragEndPosition = details.localPosition;
          _mightStartDragging = true;
          _itemPositions.clear();
        });
      },
      onPanUpdate: (details) {
        if (_mightStartDragging) {
          setState(() {
            _dragEndPosition = details.localPosition;
          });
          _updateSelectionRectangle();
        }
      },
      onPanEnd: (details) {
        setState(() {
          _mightStartDragging = false;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: iconSizeService.getConsistentSizeGridDelegate(
              constraints.maxWidth,
              minimumColumns: 3,
              childAspectRatio: 0.9,
              spacing: 8.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedItemsPaths.contains(item.path);
              
              // Get all selected items
              final selectedItems = _selectedItemsPaths.isNotEmpty
                  ? items.where((i) => _selectedItemsPaths.contains(i.path)).toList()
                  : null;
              
              return Builder(
                builder: (context) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      final RenderBox? box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final Offset position = box.localToGlobal(Offset.zero);
                        final Size size = box.size;
                        _itemPositions[item.path] = Rect.fromLTWH(
                          position.dx,
                          position.dy,
                          size.width,
                          size.height,
                        );
                      }
                    }
                  });
                  
                  Widget itemWidget = DraggableFileItem(
                    key: ValueKey(item.path),
                    item: item,
                    isSelected: isSelected,
                    isGridMode: true,
                    selectedItems: selectedItems,
                    onTap: (item, isCtrlPressed) => _selectItem(item, isCtrlPressed),
                    onDoubleTap: () => _handleItemDoubleTap(item),
                    onLongPress: (item) => _showContextMenu(item, Offset.zero),
                    onRightClick: _showContextMenu,
                  );
                  
                  // Wrap directory items with FolderDropTarget
                  if (item.type == FileItemType.directory) {
                    itemWidget = FolderDropTarget(
                      folder: item,
                      onNavigateToDirectory: _navigateToDirectory,
                      onDropSuccessful: () {
                        // Refresh the directory after a successful drop
                        _loadDirectory(_currentPath);
                      },
                      child: itemWidget,
                    );
                  }
                  
                  return itemWidget;
                }
              );
            },
          );
        },
      ),
    );
  }
  
  // Function to update selection based on rectangle bounds
  void _updateSelectionRectangle() {
    if (_dragStartPosition == null || _dragEndPosition == null) return;
    
    // Create the selection rectangle from drag points
    final Rect selectionRect = Rect.fromPoints(_dragStartPosition!, _dragEndPosition!);
    
    // Check each item's position against the selection rectangle
    bool isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
    Set<String> newSelection = isCtrlPressed ? Set.from(_selectedItemsPaths) : {};
    
    for (final entry in _itemPositions.entries) {
      final String path = entry.key;
      final Rect itemRect = entry.value;
      
      // Check if the item intersects with the selection rectangle
      if (itemRect.overlaps(selectionRect)) {
        newSelection.add(path);
      } else if (!isCtrlPressed) {
        // If not holding Ctrl, remove items outside the selection
        newSelection.remove(path);
      }
    }
    
    // Update the selection if it changed
    if (newSelection != _selectedItemsPaths) {
      setState(() {
        _selectedItemsPaths = newSelection;
      });
    }
  }
  
  Widget _buildDetailsView(List<FileItem> items, IconSizeService iconSizeService) {
    return SplitFolderView(
      items: items,
      selectedItemsPaths: _selectedItemsPaths,
      onItemTap: _selectItem,
      onItemDoubleTap: _handleItemDoubleTap,
      onItemRightClick: _showContextMenu,
      onItemLongPress: (item) => _showContextMenu(item, Offset.zero),
      onEmptyAreaTap: () => setState(() => _selectedItemsPaths = {}),
      onEmptyAreaRightClick: _showEmptyAreaContextMenu,
    );
  }

  // Handle preview panel changes
  void _handlePreviewPanelChange() {
    if (mounted) {
      // This will trigger a rebuild of the grid view
      setState(() {});
    }
  }

  void _compressItem(BuildContext context, FileItem item) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Compressing ${item.type == FileItemType.directory ? 'Folder' : 'File'}...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Compressing ${item.name}...'),
          ],
        ),
      ),
    );

    try {
      // Compress the file
      final compressionService = CompressionService();
      final outputPath = await compressionService.compressToZip(item.path);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.type == FileItemType.directory ? 'Folder' : 'File'} compressed to ${p.basename(outputPath)}'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the directory view
        setState(() {});
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compress ${item.type == FileItemType.directory ? 'folder' : 'file'}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _compressMultipleItems(BuildContext context) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Compressing Items...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Compressing ${_selectedItemsPaths.length} items...'),
          ],
        ),
      ),
    );

    try {
      final compressionService = CompressionService();
      final outputDir = p.dirname(_selectedItemsPaths.first);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = p.join(outputDir, 'compressed_$timestamp.zip');
      
      // Create a temporary directory to store the items
      final tempDir = await Directory.systemTemp.createTemp('compress_');
      try {
        // Copy all selected items to the temporary directory
        for (final path in _selectedItemsPaths) {
          final source = File(path);
          final dest = File(p.join(tempDir.path, p.basename(path)));
          await source.copy(dest.path);
        }
        
        // Compress the temporary directory
        await compressionService.compressToZip(tempDir.path, outputPath: outputPath);
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedItemsPaths.length} items compressed to ${p.basename(outputPath)}'),
              duration: const Duration(seconds: 3),
            ),
          );

          // Refresh the directory view
          setState(() {});
        }
      } finally {
        // Clean up temporary directory
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compress items: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleTabChange() {
    final tabManager = Provider.of<TabManagerService>(context, listen: false);
    final currentTab = tabManager.currentTab;
    
    if (currentTab != null && currentTab.path != _currentPath) {
      setState(() {
        _currentPath = currentTab.path;
        _isLoading = currentTab.isLoading;
        _hasError = currentTab.hasError;
        _errorMessage = currentTab.errorMessage;
      });
      
      if (!currentTab.isLoading && !currentTab.hasError) {
        _loadDirectory(currentTab.path, addToHistory: false);
      }
    }
  }

  void _showAppSelectionDialog(FileItem file) async {
    await showDialog(
      context: context,
      builder: (context) => AppSelectionDialog(
        filePath: file.path,
        fileName: file.name,
      ),
    );
  }

  Future<void> _extractFile(FileItem item) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get the parent directory
      final parentDir = p.dirname(item.path);
      
      // Run unzip command
      final result = await Process.run('unzip', ['-o', item.path, '-d', parentDir]);
      
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File extracted to ${p.basename(parentDir)}'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the directory view
        Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract file: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Add methods for multi-file operations
  void _copyMultipleItems() {
    if (_selectedItemsPaths.isEmpty) return;
    
    final items = _items.where((item) => _selectedItemsPaths.contains(item.path)).toList();
    
    setState(() {
      _clipboardItems = items;
      _isItemCut = false;
    });
    
    // Copy the paths to the system clipboard (joined with newlines)
    final String clipboardText = items.map((item) => item.path).join('\n');
    FlutterClipboard.copy(clipboardText).then((result) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Copied ${items.length} items to clipboard',
          type: NotificationType.info,
        );
      }
    });
  }
  
  void _cutMultipleItems() {
    if (_selectedItemsPaths.isEmpty) return;
    
    final items = _items.where((item) => _selectedItemsPaths.contains(item.path)).toList();
    
    setState(() {
      _clipboardItems = items;
      _isItemCut = true;
    });
    
    // Copy the paths to the system clipboard with a prefix indicating it's a cut operation
    final String clipboardText = "CUT:\n${items.map((item) => item.path).join('\n')}";
    FlutterClipboard.copy(clipboardText).then((result) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Cut ${items.length} items to clipboard',
          type: NotificationType.info,
        );
      }
    });
  }
}

/// A custom painter to draw the selection rectangle during drag selection
class SelectionRectanglePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final Color strokeColor;

  SelectionRectanglePainter({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    
    // Draw filled rectangle with semi-transparency
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);
    
    // Draw rectangle border
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(SelectionRectanglePainter oldDelegate) {
    return start != oldDelegate.start ||
           end != oldDelegate.end ||
           color != oldDelegate.color ||
           strokeColor != oldDelegate.strokeColor;
  }
}