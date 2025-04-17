import 'dart:io';
import 'dart:math';
import 'dart:ui'; // Import for ImageFilter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:clipboard/clipboard.dart';
import 'package:window_manager/window_manager.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import '../services/view_mode_service.dart';
import '../services/status_bar_service.dart';
import '../services/icon_size_service.dart';
import '../services/theme_service.dart';
import '../services/usb_drive_service.dart';
import '../services/preview_panel_service.dart';
import '../services/app_service.dart';
import '../services/file_association_service.dart';
import '../widgets/file_item_widget.dart';
import '../widgets/grid_item_widget.dart';
import '../widgets/split_folder_view.dart';
import '../widgets/bookmark_sidebar.dart';
import '../widgets/status_bar.dart';
import '../widgets/preview_panel.dart';
import '../widgets/app_selection_dialog.dart';
import '../widgets/column_view_widget.dart';
import 'file_associations_screen.dart';

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

class _FileExplorerScreenState extends State<FileExplorerScreen> with WindowListener, TickerProviderStateMixin {
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode(); // Add focus node for keyboard events
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _isSearchActive = false;
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
  
  // Search related state variables
  List<FileItem> _searchResults = [];
  bool _isSearching = false;
  
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
  bool _isDragging = false;
  Offset? _dragStartPosition;
  Offset? _dragEndPosition;
  final Map<String, Rect> _itemPositions = {}; // Store positions of items for hit testing
  final GlobalKey _gridViewKey = GlobalKey(); // Key for the grid container
  bool _isSelectionCompleted = false; // Track if selection was completed properly

  // Added state variables for drag selection
  Offset? _initialPanPosition;
  bool _mightStartDragging = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
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
      _isDragging = false;
      _dragStartPosition = null;
      _dragEndPosition = null;
      _mightStartDragging = false;
      _initialPanPosition = null;
    });

    try {
      final items = await _fileService.listDirectory(path);
      
      setState(() {
        _items = items;
        _isLoading = false;
        
        // Reset selection when changing directories
        _selectedItemsPaths = {};
      });
    } catch (e) {
      _handleError('Failed to load directory: $e');
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
    _loadDirectory(path);
  }

  void _navigateBack() {
    if (_navigationHistory.isNotEmpty) {
      // Add current path to forward history
      _forwardHistory.add(_currentPath);
      // Navigate to previous path
      final previousPath = _navigationHistory.removeLast();
      _loadDirectory(previousPath, addToHistory: false);
    }
  }

  void _navigateForward() {
    if (_forwardHistory.isNotEmpty) {
      // Add current path to backward history
      _navigationHistory.add(_currentPath);
      // Navigate to forward path
      final forwardPath = _forwardHistory.removeLast();
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

  Future<void> _showOptionsDialog(FileItem item) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(item.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'rename'),
            child: Text('Rename'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (result == 'rename') {
      _showRenameDialog(item);
    } else if (result == 'delete') {
      _showDeleteConfirmation(item);
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
              Icon(Icons.open_in_new),
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
              Icon(Icons.apps),
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
            Icon(Icons.copy),
            SizedBox(width: 8),
            Text(hasMultipleSelection ? 'Copy Items' : 'Copy'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'cut',
        child: Row(
          children: [
            Icon(Icons.cut),
            SizedBox(width: 8),
            Text(hasMultipleSelection ? 'Cut Items' : 'Cut'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
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
                Icon(Icons.edit),
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
                Icon(isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add),
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
                Icon(Icons.terminal),
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
                Icon(Icons.eject),
                SizedBox(width: 8),
                Text('Unmount Drive'),
              ],
            ),
          ),
          
        // Properties always available
        PopupMenuItem<String>(
          value: 'properties',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Properties'),
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
      case 'properties':
        _showPropertiesDialog(item);
        break;
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
          builder: (BuildContext context) {
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
          Navigator.of(context).pop();
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
          Navigator.of(context).pop();
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
  
  Future<void> _pasteItems() async {
    // First try to use the internal clipboard
    if (_clipboardItems != null && _clipboardItems!.isNotEmpty) {
      await _pasteItemsFromInternalClipboard();
    } else {
      // If internal clipboard is empty, try system clipboard
      await _pasteFromSystemClipboard();
    }
  }

  Future<void> _pasteFromSystemClipboard() async {
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
    if (_clipboardItems == null || _clipboardItems!.isEmpty) return;
    
    try {
      // Show progress dialog for multiple pastes
      if (_clipboardItems!.length > 1 && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(_isItemCut ? 'Moving Files' : 'Copying Files'),
              content: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(width: 16),
                  Text('Processing ${_clipboardItems!.length} items...'),
                ],
              ),
            );
          },
        );
      }
      
      int successCount = 0;
      List<String> errors = [];
      
      // Process each item in the clipboard
      for (final item in _clipboardItems!) {
        final String sourcePath = item.path;
        final String itemName = item.name;
        final String targetPath = p.join(_currentPath, itemName);
        
        // Check if target already exists
        final bool destinationExists = await _fileExists(targetPath);
        
        if (destinationExists) {
          // File or directory already exists, show conflict dialog
          if (!mounted) continue; // Check if widget is still mounted
          
          final bool? overwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('File Exists'),
              content: Text('$itemName already exists in this location. Overwrite?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Overwrite'),
                ),
              ],
            ),
          );
          
          if (overwrite != true) continue; // User canceled or closed dialog
        }
        
        try {
          if (_isItemCut) {
            // Move operation
            await _fileService.moveFileOrDirectory(sourcePath, _currentPath);
          } else {
            // Copy operation
            await _fileService.copyFileOrDirectory(sourcePath, _currentPath);
          }
          successCount++;
        } catch (e) {
          errors.add('$itemName: $e');
        }
      }
      
      // Clear clipboard after cut-paste
      if (_isItemCut && successCount > 0) {
        setState(() {
          _clipboardItems = null;
        });
      }
      
      // Dismiss progress dialog if it was shown
      if (_clipboardItems!.length > 1 && mounted) {
        Navigator.of(context).pop();
      }
      
      // Show result notification
      if (mounted) {
        if (errors.isEmpty) {
          // All operations succeeded
          NotificationService.showNotification(
            context,
            message: _isItemCut 
                ? 'Moved $successCount items' 
                : 'Copied $successCount items',
            type: NotificationType.success,
          );
        } else {
          // Some operations failed
          NotificationService.showNotification(
            context,
            message: 'Completed with ${errors.length} errors',
            type: NotificationType.warning,
          );
          
          // Show detailed error dialog for multiple errors
          if (errors.length > 1) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Operation Errors'),
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
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          }
        }
      }
      
      // Refresh directory contents
      _loadDirectory(_currentPath);
      
    } catch (e) {
      // Handle top-level errors
      if (mounted) {
        // Dismiss progress dialog if it was shown
        if (_clipboardItems!.length > 1) {
          Navigator.of(context).pop();
        }
        
        NotificationService.showNotification(
          context,
          message: 'Error: $e',
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

  @override
  Widget build(BuildContext context) {
    // Provider services
    final statusBarService = Provider.of<StatusBarService>(context);
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    final viewModeService = Provider.of<ViewModeService>(context);
    
    // Update animation controllers based on panel visibility
    if (previewPanelService.showPreviewPanel && _previewPanelAnimation.status != AnimationStatus.completed) {
      _previewPanelAnimation.forward();
    } else if (!previewPanelService.showPreviewPanel && _previewPanelAnimation.status != AnimationStatus.dismissed) {
      _previewPanelAnimation.reverse();
    }
    
    if (_showBookmarkSidebar && _bookmarkSidebarAnimation.status != AnimationStatus.completed) {
      _bookmarkSidebarAnimation.forward();
    } else if (!_showBookmarkSidebar && _bookmarkSidebarAnimation.status != AnimationStatus.dismissed && 
              _bookmarkSidebarAnimation.status != AnimationStatus.reverse) {
      _bookmarkSidebarAnimation.reverse();
    }
    
    final scaffold = Scaffold(
      // Use a solid background for the main content but keep bookmarks sidebar transparent for blur effect
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      // Remove the container with gradient so we can see through to the desktop
      body: Column(
        children: [
          // Main content area with bookmarks sidebar and content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bookmark sidebar with frosted glass effect and animation
                AnimatedBuilder(
                  animation: _bookmarkSidebarAnimation,
                  builder: (context, child) {
                    // Calculate animations
                    final slideValue = Tween<double>(begin: -220, end: 0)
                        .animate(CurvedAnimation(parent: _bookmarkSidebarAnimation, curve: Curves.easeOutCubic))
                        .value;
                    
                    final opacityValue = Tween<double>(begin: 0, end: 1)
                        .animate(CurvedAnimation(parent: _bookmarkSidebarAnimation, curve: Curves.easeOut))
                        .value;
                    
                    // Don't show at all if completely hidden and animation is done
                    if (!_showBookmarkSidebar && _bookmarkSidebarAnimation.isDismissed) {
                      return const SizedBox.shrink();
                    }
                    
                    return Transform.translate(
                      offset: Offset(slideValue, 0),
                      child: Opacity(
                        opacity: opacityValue,
                        child: Stack(
                          children: [
                            // This is the backdrop that will be blurred
                            Positioned.fill(
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                            // Actual blur effect
                            ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  width: 220,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.black.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  // The actual BookmarkSidebar
                                  child: BookmarkSidebar(
                                    onNavigate: _navigateToDirectory,
                                    currentPath: _currentPath,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                // Main content column with app bar and content
                Expanded(
                  child: Container(
                    // Add a solid background for the main content area
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF121212).withValues(alpha: 1.0)
                          : const Color(0xFFF5F5F5).withValues(alpha: 1.0),
                    ),
                    child: Column(
                      children: [
                        // Top app bar with navigation and breadcrumbs
                        _buildAppBar(context),
                        
                        // Content area with optional preview panel and animation
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Main content area
                              Expanded(
                                child: _buildFileView(viewModeService),
                              ),
                              
                              // Animated preview panel
                              AnimatedBuilder(
                                animation: _previewPanelAnimation,
                                builder: (context, child) {
                                  // Calculate animations
                                  final slideValue = Tween<double>(begin: 300, end: 0)
                                      .animate(CurvedAnimation(parent: _previewPanelAnimation, curve: Curves.easeOutCubic))
                                      .value;
                                  
                                  final opacityValue = Tween<double>(begin: 0, end: 1)
                                      .animate(CurvedAnimation(parent: _previewPanelAnimation, curve: Curves.easeOut))
                                      .value;
                                  
                                  // Don't show at all if completely hidden and animation is done
                                  if (!previewPanelService.showPreviewPanel && _previewPanelAnimation.isDismissed) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Transform.translate(
                                    offset: Offset(slideValue, 0),
                                    child: Opacity(
                                      opacity: opacityValue,
                                      child: PreviewPanel(
                                        onNavigate: _navigateToDirectory,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Status bar
          if (statusBarService.showStatusBar)
            StatusBar(
              items: _items,
              showIconControls: statusBarService.showIconControls,
            ),
        ],
      ),
    );
    
    // Wrap in Shortcuts and Actions for keyboard shortcuts
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Add search shortcut (Ctrl+F)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): 
            const SearchIntent(),
        // Add escape key to close search
        LogicalKeySet(LogicalKeyboardKey.escape): 
            const CloseSearchIntent(),
        // Add Ctrl+ to increase icon size
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal):
            const ZoomIntent(zoomIn: true),
        // Add Ctrl- to decrease icon size
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus):
            const ZoomIntent(zoomIn: false),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (SearchIntent intent) {
              if (!_isSearchActive) {
                _toggleSearch();
              }
              return null;
            },
          ),
          CloseSearchIntent: CallbackAction<CloseSearchIntent>(
            onInvoke: (CloseSearchIntent intent) {
              if (_isSearchActive) {
                _toggleSearch();
              }
              return null;
            },
          ),
          // Add action for handling zoom intents
          ZoomIntent: CallbackAction<ZoomIntent>(
            onInvoke: (ZoomIntent intent) {
              final iconSizeService = Provider.of<IconSizeService>(context, listen: false);
              final viewModeService = Provider.of<ViewModeService>(context, listen: false);
              
              if (intent.zoomIn) {
                // Increase icon size
                if (viewModeService.isGrid) {
                  iconSizeService.increaseGridIconSize();
                } else {
                  iconSizeService.increaseListIconSize();
                }
              } else {
                // Decrease icon size
                if (viewModeService.isGrid) {
                  iconSizeService.decreaseGridIconSize();
                } else {
                  iconSizeService.decreaseListIconSize();
                }
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: scaffold,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onPanStart: (details) {
        // Make the app bar draggable
        windowManager.startDragging();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDarkMode 
                  ? Colors.black 
                  : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
        ),
        child: PreferredSize(
          preferredSize: Size.fromHeight(52), // Increased from 49px to 52px to match sidebar header
          child: AppBar(
            leadingWidth: 100, // Provide enough space for two icons
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _navigationHistory.isEmpty ? null : _navigateBack,
                  tooltip: 'Go back',
                  iconSize: 22, // Adjusted size to match bookmark sidebar
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  constraints: BoxConstraints(), // Remove default constraints
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _forwardHistory.isEmpty ? null : _navigateForward,
                  tooltip: 'Go forward',
                  iconSize: 22, // Adjusted size to match bookmark sidebar
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  constraints: BoxConstraints(), // Remove default constraints
                ),
              ],
            ),
            title: _isSearchActive ? _buildSearchBar() : _buildPathBreadcrumbs(), // Show search bar or breadcrumbs
            titleSpacing: 0,
            elevation: 0, // Remove elevation to match bookmark header
            backgroundColor: Colors.transparent, // Make transparent to show the Container's decoration
            actions: [
              _buildActionButtons(context),
              _buildWindowControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPathBreadcrumbs() {
    final pathParts = _currentPath.split('/');
    
    // Filter out empty parts (like at the beginning of an absolute path)
    final validParts = pathParts.where((part) => part.isNotEmpty).toList();
    
    return SizedBox(
      key: _breadcrumbKey,
      height: 52, // Increased from 49px to 52px to match new heights
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Root directory
          _buildBreadcrumbItem('/', 'Root', validParts.isEmpty, 0),
          
          // Path parts
          for (int i = 0; i < validParts.length; i++)
            _buildBreadcrumbItem(
              '/${validParts.sublist(0, i + 1).join('/')}',
              validParts[i],
              i == validParts.length - 1,
              i + 1,
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String path, String label, bool isLast, int index) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index > 0)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: isLast ? null : () {
            if (path != _currentPath) {
              _navigationHistory.add(_currentPath);
              _forwardHistory.clear(); // Clear forward history when using breadcrumbs
              _loadDirectory(path);
            }
          },
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              color: isLast 
                  ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final statusBarService = Provider.of<StatusBarService>(context);
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search button
        IconButton(
          icon: Icon(_isSearchActive ? Icons.close : Icons.search),
          iconSize: 22,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          constraints: BoxConstraints(),
          tooltip: _isSearchActive ? 'Close Search' : 'Search Files',
          onPressed: _toggleSearch,
        ),
        // Replace the IconButton with PopupMenuButton for theme selection
        PopupMenuButton<ThemeMode>(
          tooltip: 'Theme Settings',
          icon: const Icon(Icons.dark_mode, size: 22),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          constraints: BoxConstraints(),
          onSelected: (ThemeMode mode) {
            final themeService = Provider.of<ThemeService>(context, listen: false);
            themeService.setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) {
            final themeService = Provider.of<ThemeService>(context, listen: false);
            return <PopupMenuEntry<ThemeMode>>[
              CheckedPopupMenuItem<ThemeMode>(
                value: ThemeMode.system,
                checked: themeService.isSystemMode,
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto),
                    SizedBox(width: 8),
                    Text('System Theme'),
                  ],
                ),
              ),
              CheckedPopupMenuItem<ThemeMode>(
                value: ThemeMode.light,
                checked: themeService.isLightMode,
                child: Row(
                  children: [
                    Icon(Icons.light_mode),
                    SizedBox(width: 8),
                    Text('Light Theme'),
                  ],
                ),
              ),
              CheckedPopupMenuItem<ThemeMode>(
                value: ThemeMode.dark,
                checked: themeService.isDarkMode,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode),
                    SizedBox(width: 8),
                    Text('Dark Theme'),
                  ],
                ),
              ),
            ];
          },
        ),
        IconButton(
          icon: Icon(
            Provider.of<ViewModeService>(context).viewMode == ViewMode.grid
                ? Icons.grid_view
                : Provider.of<ViewModeService>(context).viewMode == ViewMode.list
                    ? Icons.view_list
                    : Provider.of<ViewModeService>(context).viewMode == ViewMode.column
                        ? Icons.view_column
                        : Icons.splitscreen,
          ),
          iconSize: 22,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          constraints: BoxConstraints(),
          tooltip: 'Change View Mode',
          onPressed: () {
            final viewModeService = Provider.of<ViewModeService>(context, listen: false);
            // Cycle through view modes (list -> grid -> column -> split -> list)
            if (viewModeService.viewMode == ViewMode.list) {
              viewModeService.transitionToViewMode(ViewMode.grid);
            } else if (viewModeService.viewMode == ViewMode.grid) {
              viewModeService.transitionToViewMode(ViewMode.column);
            } else if (viewModeService.viewMode == ViewMode.column) {
              viewModeService.transitionToViewMode(ViewMode.split);
            } else {
              viewModeService.transitionToViewMode(ViewMode.list);
            }
          },
        ),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, size: 22),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          offset: const Offset(0, 40),
          onSelected: (String value) {
            if (value == 'file') {
              _showCreateDialog(false);
            } else if (value == 'folder') {
              _showCreateDialog(true);
            } else if (value == 'toggle_bookmarks') {
              _toggleBookmarkSidebar();
            } else if (value == 'refresh') {
              _loadDirectory(_currentPath);
            } else if (value == 'open_terminal') {
              _openCurrentDirectoryInTerminal();
            } else if (value == 'paste') {
              _pasteItems();
            } else if (value == 'toggle_status_bar') {
              statusBarService.toggleStatusBar();
            } else if (value == 'toggle_icon_controls') {
              statusBarService.toggleIconControls();
            } else if (value == 'toggle_preview_panel') {
              previewPanelService.togglePreviewPanel();
              
              // If toggling on and there's a selected item, make sure it's set in the service
              if (previewPanelService.showPreviewPanel && _selectedItemsPaths.length == 1) {
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
                  previewPanelService.setSelectedItem(selectedItem);
                }
              }
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'toggle_bookmarks',
              child: Row(
                children: [
                  Icon(_showBookmarkSidebar ? Icons.bookmark : Icons.bookmark_border),
                  const SizedBox(width: 8),
                  Text(_showBookmarkSidebar ? 'Hide Bookmarks' : 'Show Bookmarks'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_preview_panel',
              child: Row(
                children: [
                  Icon(
                    previewPanelService.showPreviewPanel
                        ? Icons.preview
                        : Icons.preview_outlined,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    previewPanelService.showPreviewPanel
                        ? 'Hide Preview Panel'
                        : 'Show Preview Panel',
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_status_bar',
              child: Row(
                children: [
                  Icon(
                    statusBarService.showStatusBar
                        ? Icons.info
                        : Icons.info_outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusBarService.showStatusBar
                        ? 'Hide Status Bar'
                        : 'Show Status Bar',
                  ),
                ],
              ),
            ),
            if (statusBarService.showStatusBar)
              PopupMenuItem<String>(
                value: 'toggle_icon_controls',
                child: Row(
                  children: [
                    Icon(
                      statusBarService.showIconControls
                          ? Icons.zoom_in
                          : Icons.zoom_out_map,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusBarService.showIconControls
                              ? 'Hide Icon Controls'
                              : 'Show Icon Controls',
                        ),
                        Text(
                          'Shortcuts: Ctrl+=, Ctrl+-',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'file',
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file),
                  SizedBox(width: 8),
                  Text('New File'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'folder',
              child: Row(
                children: [
                  Icon(Icons.create_new_folder),
                  SizedBox(width: 8),
                  Text('New Folder'),
                ],
              ),
            ),
            if (_clipboardItems != null && _clipboardItems!.isNotEmpty)
              PopupMenuItem<String>(
                value: 'paste',
                child: Row(
                  children: [
                    Icon(Icons.content_paste),
                    const SizedBox(width: 8),
                    Text(_isItemCut ? 'Paste (Cut)' : 'Paste (Copy)'),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'open_terminal',
              child: Row(
                children: [
                  Icon(Icons.terminal),
                  SizedBox(width: 8),
                  Text('Open in Terminal'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWindowControls() {
    return Row(
      children: [
        _buildWindowControlButton(
          icon: Icons.minimize,
          tooltip: 'Minimize',
          onPressed: () async {
            await windowManager.minimize();
          },
        ),
        _buildWindowControlButton(
          icon: _isMaximized ? Icons.crop_square : Icons.crop_din,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _buildWindowControlButton(
          icon: Icons.close,
          tooltip: 'Close',
          isCloseButton: true,
          onPressed: () async {
            await windowManager.close();
          },
        ),
      ],
    );
  }

  Widget _buildWindowControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isCloseButton = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: InkWell(
            onTap: onPressed,
            hoverColor: isCloseButton 
              ? Colors.red 
              : (isDarkMode ? Colors.white.withValues(alpha: 26) : Colors.black.withValues(alpha: 26)),
            child: Container(
              width: 36,
              height: 36,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  icon,
                  size: 16,
                  color: isCloseButton && !isDarkMode
                    ? Colors.red.shade700
                    : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileView(ViewModeService viewModeService) {
    // Handle loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle error state
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(_errorMessage),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDirectory(_currentPath, addToHistory: false),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get the items to display (either all items or search results)
    final displayItems = _isSearchActive && _isSearching 
        ? _searchResults 
        : _items;

    // Handle empty directory or no search results
    if (displayItems.isEmpty) {
      return GestureDetector(
        onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
        behavior: HitTestBehavior.opaque,  // Ensure taps are registered on transparent areas
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSearchActive ? Icons.search_off : Icons.folder_off, 
                color: Colors.grey, 
                size: 48
              ),
              SizedBox(height: 16),
              Text(
                _isSearchActive 
                    ? 'No results found for "${_searchController.text}"' 
                    : 'This folder is empty'
              ),
              if (_isSearchActive) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Clear Search', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    // Display content based on view mode with drag selection overlay
    switch (viewModeService.viewMode) {
      case ViewMode.grid:
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Show search results indicator
                  if (_isSearchActive && _isSearching) 
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Found ${_searchResults.length} results for "${_searchController.text}"',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  
                  // Grid view with items
                  Expanded(
                    child: GestureDetector(
                      key: _gridViewKey,
                      onTap: () {
                        // Check if we recently completed a selection
                        if (_isSelectionCompleted) {
                          setState(() {
                            _isSelectionCompleted = false;
                          });
                          return;
                        }
                        
                        // Clear selection only if not completing a drag operation
                        if (!_isDragging) {
                          setState(() {
                            _selectedItemsPaths = {};
                            _dragStartPosition = null;
                            _dragEndPosition = null;
                            _isSelectionCompleted = false;  // Reset completed flag
                            
                            // Clear the preview panel
                            Provider.of<PreviewPanelService>(context, listen: false)
                                .setSelectedItem(null);
                          });
                        }
                      },
                      onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
                      // Add drag selection functionality
                      onPanDown: (details) {
                        // Reset any existing drag state
                        _mightStartDragging = false;
                        
                        // Store the initial pan position but don't immediately start dragging
                        // This allows for distinguishing between clicks and drags
                        _initialPanPosition = details.globalPosition;
                        
                        // Only start tracking for possible dragging if not clicking on an item
                        final hitPosition = details.globalPosition;
                        bool hitOnItem = false;
                        
                        // See if we hit any item directly
                        for (final item in displayItems) {
                          final rect = _itemPositions[item.path];
                          if (rect != null && rect.contains(hitPosition)) {
                            hitOnItem = true;
                            break;
                          }
                        }
                        
                        // Mark that we might start dragging, but don't actually start yet
                        // We'll decide in onPanUpdate if this is a drag or just a click
                        _mightStartDragging = !hitOnItem && !HardwareKeyboard.instance.isControlPressed;
                      },
                      onPanUpdate: (details) {
                        // If we're already dragging, update the selection rectangle
                        if (_isDragging) {
                          setState(() {
                            _dragEndPosition = details.globalPosition;
                            
                            // Update selected items based on selection rectangle
                            final selectionRect = _getSelectionRect();
                            _selectedItemsPaths = _getItemsInSelectionArea(selectionRect);
                            
                            // Update preview panel if exactly one item is selected
                            if (_selectedItemsPaths.length == 1) {
                              final selectedPath = _selectedItemsPaths.first;
                              final selectedItem = displayItems.firstWhere(
                                (item) => item.path == selectedPath,
                                orElse: () => FileItem(
                                  path: '',
                                  name: '',
                                  type: FileItemType.unknown,
                                ),
                              );
                              
                              if (selectedItem.type != FileItemType.unknown) {
                                Provider.of<PreviewPanelService>(context, listen: false)
                                    .setSelectedItem(selectedItem);
                              }
                            }
                          });
                        } 
                        // If we might start dragging and have moved enough, start actual dragging
                        else if (_mightStartDragging && _initialPanPosition != null) {
                          // Calculate distance moved
                          final distance = (_initialPanPosition! - details.globalPosition).distance;
                          // Only start dragging if moved more than a small threshold (prevents accidental drags)
                          if (distance > 5.0) {
                            setState(() {
                              _isDragging = true;
                              _dragStartPosition = _initialPanPosition;
                              _dragEndPosition = details.globalPosition;
                              
                              // Clear selection when starting new drag
                              _selectedItemsPaths = {};
                              
                              // Clear the preview panel
                              Provider.of<PreviewPanelService>(context, listen: false)
                                  .setSelectedItem(null);
                            });
                          }
                        }
                      },
                      onPanEnd: (details) {
                        _cleanupDragSelection();
                      },
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: 100.0 * Provider.of<IconSizeService>(context).gridUIScale),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: Provider.of<IconSizeService>(context).gridItemExtent,
                          childAspectRatio: 1.0 / (Provider.of<IconSizeService>(context).gridUIScale > 1.2 ? 1.1 : 1.0),
                          crossAxisSpacing: 5.0,
                          mainAxisSpacing: 5.0,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return ItemPositionTracker(
                                key: ValueKey(item.path),
                                path: item.path,
                                onPositionChanged: _registerItemPosition,
                                child: GridItemWidget(
                                  key: ValueKey(item.path),
                                  item: item,
                                  onTap: _selectItem,
                                  onDoubleTap: () => _handleItemDoubleTap(item),
                                  onLongPress: _showOptionsDialog,
                                  onRightClick: _showContextMenu,
                                  isSelected: _selectedItemsPaths.contains(item.path),
                                ),
                              );
                            }
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Draw selection rectangle if dragging
            if (_isDragging && _dragStartPosition != null && _dragEndPosition != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: SelectionRectanglePainter(
                    startPoint: _dragStartPosition!,
                    endPoint: _dragEndPosition!,
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
          ],
        );

      case ViewMode.list:
        return Stack(
          children: [
            Column(
              children: [
                // Show search results indicator
                if (_isSearchActive && _isSearching) 
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.withValues(alpha: 0.1)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Found ${_searchResults.length} results for "${_searchController.text}"',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                
                // List view with items
                Expanded(
                  child: GestureDetector(
                    key: _gridViewKey,
                    onTap: () {
                      // Check if we recently completed a selection
                      if (_isSelectionCompleted) {
                        setState(() {
                          _isSelectionCompleted = false;
                        });
                        return;
                      }
                      
                      // Clear selection only if not completing a drag operation
                      if (!_isDragging) {
                        setState(() {
                          _selectedItemsPaths = {};
                          _dragStartPosition = null;
                          _dragEndPosition = null;
                          _isSelectionCompleted = false;  // Reset completed flag
                          
                          // Clear the preview panel
                          Provider.of<PreviewPanelService>(context, listen: false)
                              .setSelectedItem(null);
                        });
                      }
                    },
                    onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
                    // Add drag selection functionality
                    onPanDown: (details) {
                      // Reset any existing drag state
                      _mightStartDragging = false;
                      
                      // Store the initial pan position but don't immediately start dragging
                      // This allows for distinguishing between clicks and drags
                      _initialPanPosition = details.globalPosition;
                      
                      // Only start tracking for possible dragging if not clicking on an item
                      final hitPosition = details.globalPosition;
                      bool hitOnItem = false;
                      
                      // See if we hit any item directly
                      for (final item in displayItems) {
                        final rect = _itemPositions[item.path];
                        if (rect != null && rect.contains(hitPosition)) {
                          hitOnItem = true;
                          break;
                        }
                      }
                      
                      // Mark that we might start dragging, but don't actually start yet
                      // We'll decide in onPanUpdate if this is a drag or just a click
                      _mightStartDragging = !hitOnItem && !HardwareKeyboard.instance.isControlPressed;
                    },
                    onPanUpdate: (details) {
                      // If we're already dragging, update the selection rectangle
                      if (_isDragging) {
                        setState(() {
                          _dragEndPosition = details.globalPosition;
                          
                          // Update selected items based on selection rectangle
                          final selectionRect = _getSelectionRect();
                          _selectedItemsPaths = _getItemsInSelectionArea(selectionRect);
                          
                          // Update preview panel if exactly one item is selected
                          if (_selectedItemsPaths.length == 1) {
                            final selectedPath = _selectedItemsPaths.first;
                            final selectedItem = displayItems.firstWhere(
                              (item) => item.path == selectedPath,
                              orElse: () => FileItem(
                                path: '',
                                name: '',
                                type: FileItemType.unknown,
                              ),
                            );
                            
                            if (selectedItem.type != FileItemType.unknown) {
                              Provider.of<PreviewPanelService>(context, listen: false)
                                  .setSelectedItem(selectedItem);
                            }
                          }
                        });
                      } 
                      // If we might start dragging and have moved enough, start actual dragging
                      else if (_mightStartDragging && _initialPanPosition != null) {
                        // Calculate distance moved
                        final distance = (_initialPanPosition! - details.globalPosition).distance;
                        // Only start dragging if moved more than a small threshold (prevents accidental drags)
                        if (distance > 5.0) {
                          setState(() {
                            _isDragging = true;
                            _dragStartPosition = _initialPanPosition;
                            _dragEndPosition = details.globalPosition;
                            
                            // Clear selection when starting new drag
                            _selectedItemsPaths = {};
                            
                            // Clear the preview panel
                            Provider.of<PreviewPanelService>(context, listen: false)
                                .setSelectedItem(null);
                          });
                        }
                      }
                    },
                    onPanEnd: (details) {
                      _cleanupDragSelection();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(bottom: 100.0 * Provider.of<IconSizeService>(context).listUIScale),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        return ItemPositionTracker(
                          key: ValueKey(item.path),
                          path: item.path,
                          onPositionChanged: _registerItemPosition,
                          child: FileItemWidget(
                            key: ValueKey(item.path),
                            item: item,
                            onTap: _selectItem,
                            onDoubleTap: () => _handleItemDoubleTap(item),
                            onLongPress: _showOptionsDialog,
                            onRightClick: _showContextMenu,
                            isSelected: _selectedItemsPaths.contains(item.path),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Draw selection rectangle if dragging
            if (_isDragging && _dragStartPosition != null && _dragEndPosition != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: SelectionRectanglePainter(
                    startPoint: _dragStartPosition!,
                    endPoint: _dragEndPosition!,
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
          ],
        );

      case ViewMode.split:
        return SplitFolderView(
          items: displayItems,
          onItemTap: _selectItem,
          onItemDoubleTap: _handleItemDoubleTap,
          onItemLongPress: _showOptionsDialog,
          onItemRightClick: _showContextMenu,
          selectedItemsPaths: _selectedItemsPaths,
          onEmptyAreaTap: () {
            setState(() {
              _selectedItemsPaths = {};
            });
          },
          onEmptyAreaRightClick: _showEmptySpaceContextMenu,
        );
      case ViewMode.column:
        return ColumnViewWidget(
          currentPath: _currentPath,
          items: displayItems,
          onNavigate: _navigateToDirectory,
          onItemTap: _selectItem,
          onItemDoubleTap: _handleItemDoubleTap,
          onItemLongPress: _showOptionsDialog,
          onItemRightClick: _showContextMenu,
          selectedItemsPaths: _selectedItemsPaths,
          onEmptyAreaTap: () {
            setState(() {
              _selectedItemsPaths = {};
            });
          },
          onEmptyAreaRightClick: _showEmptySpaceContextMenu,
        );
    }
  }

  /// Check if a directory is a mount point
  Future<bool> _isDirectoryMountPoint(String path) async {
    try {
      // Run the findmnt command to check if this is a mount point
      final ProcessResult result = await Process.run('findmnt', ['-n', path]);
      
      // If the command returns successfully with output, it's a mount point
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Show confirmation dialog for unmounting a drive
  Future<void> _showUnmountConfirmation(FileItem item) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unmount Drive'),
        content: Text('Are you sure you want to unmount ${item.name}?\n\nAll file operations on this drive will be unavailable until reconnected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unmount'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Show loading indicator
    if (!mounted) return;
    
    NotificationService.showNotification(
      context,
      message: 'Unmounting ${item.name}...',
          type: NotificationType.info,
      duration: const Duration(milliseconds: 750),
    );
    
    try {
      final success = await _usbDriveService.unmountDrive(item.path);
      
      if (success) {
        // If current directory is the unmounted one or a subdirectory, navigate to parent
        if (_currentPath == item.path || _currentPath.startsWith('${item.path}/')) {
          final parentPath = p.dirname(_currentPath);
          _navigateToDirectory(parentPath);
        } else {
          // Just refresh current directory
          _loadDirectory(_currentPath);
        }
        
        // Show success notification
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: '${item.name} unmounted successfully',
            type: NotificationType.success,
          );
        }
      } else {
        // Show error notification
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Failed to unmount drive. Make sure it\'s not in use.',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      // Show error notification
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Error: ${e.toString()}',
          type: NotificationType.error,
        );
      }
    }
  }

  // Re-implement the _showEmptySpaceContextMenu method that was deleted
  void _showEmptySpaceContextMenu(Offset position) async {
    // Deselect any selected items when right-clicking on empty space
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
    
    final menuItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'new_folder',
        child: Row(
          children: [
            Icon(Icons.create_new_folder),
            SizedBox(width: 8),
            Text('New Folder'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'new_file',
        child: Row(
          children: [
            Icon(Icons.note_add),
            SizedBox(width: 8),
            Text('New File'),
          ],
        ),
      ),
    ];
    
    // Add paste option if clipboard has items
    if (_clipboardItems != null && _clipboardItems!.isNotEmpty) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'paste',
          child: Row(
            children: [
              Icon(Icons.content_paste),
              SizedBox(width: 8),
              Text(_isItemCut ? 'Paste (Cut)' : 'Paste (Copy)'),
            ],
          ),
        ),
      );
    }
    
    // Add divider before additional options
    menuItems.add(const PopupMenuDivider());
    
    // Additional common options
    menuItems.addAll([
      PopupMenuItem<String>(
        value: 'open_in_terminal',
        child: Row(
          children: [
            Icon(Icons.terminal),
            SizedBox(width: 8),
            Text('Open in Terminal'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'refresh',
        child: Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 8),
            Text('Refresh'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'file_associations',
        child: Row(
          children: [
            Icon(Icons.settings_applications),
            SizedBox(width: 8),
            Text('File Associations'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'properties',
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Text('Folder Properties'),
          ],
        ),
      ),
    ]);
    
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      items: menuItems,
    );
    
    // Process the selected menu option
    if (result == null || !mounted) return;
    
    switch (result) {
      case 'new_folder':
        _showCreateDialog(true);
        break;
      case 'new_file':
        _showCreateDialog(false);
        break;
      case 'paste':
        _pasteItems();
        break;
      case 'open_in_terminal':
        _openCurrentDirectoryInTerminal();
        break;
      case 'refresh':
        _loadDirectory(_currentPath);
        break;
      case 'file_associations':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FileAssociationsScreen(),
          ),
        );
        break;
      case 'properties':
        // Create a FileItem for the current directory and show its properties
        final currentDirItem = FileItem(
          path: _currentPath,
          name: p.basename(_currentPath),
          type: FileItemType.directory,
        );
        _showPropertiesDialog(currentDirItem);
        break;
    }
  }

  // Re-implement the _openCurrentDirectoryInTerminal method that was deleted
  void _openCurrentDirectoryInTerminal() async {
    try {
      // Try using ptyxis with --working-directory, then fall back to other terminals if needed
      final String command = 'ptyxis --new-window --working-directory "$_currentPath" || '
                           'gnome-terminal --working-directory="$_currentPath" || '
                           'xfce4-terminal --working-directory="$_currentPath" || '
                           'konsole --workdir="$_currentPath" || '
                           'xterm -e "cd \'$_currentPath\' && bash"';
      
      // Use underscore to ignore the result
      await Process.run('sh', ['-c', command]);
      
      // Don't check exit code as we're using fallbacks with ||
      // Instead, just show success message if we get here
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Opened current directory in terminal',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to open terminal: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  // Re-implement the _openInTerminal method that was deleted
  void _openInTerminal(FileItem item) async {
    try {
      final String command;
      
      if (item.type == FileItemType.directory) {
        // For directories, use ptyxis with --working-directory
        command = 'ptyxis --new-window --working-directory "${item.path}" || '
                'gnome-terminal --working-directory="${item.path}" || '
                'xfce4-terminal --working-directory="${item.path}" || '
                'konsole --workdir="${item.path}" || '
                'xterm -e "cd \'${item.path}\' && bash"';
      } else {
        // For files, determine appropriate action based on file type
        final String dirname = p.dirname(item.path);
        
        if (item.fileExtension == '.sh') {
          // For shell scripts
          command = 'ptyxis --new-window --working-directory "$dirname" --command "bash \'${item.path}\'" || '
                  'gnome-terminal -- bash -c "bash \'${item.path}\'; exec bash" || '
                  'xfce4-terminal -- bash -c "bash \'${item.path}\'; exec bash" || '
                  'konsole -e bash -c "bash \'${item.path}\'; exec bash" || '
                  'xterm -e "bash \'${item.path}\'; exec bash"';
        } else if (item.fileExtension == '.py') {
          // For Python scripts
          command = 'ptyxis --new-window --working-directory "$dirname" --command "python3 \'${item.path}\'" || '
                  'gnome-terminal -- bash -c "python3 \'${item.path}\'; exec bash" || '
                  'xfce4-terminal -- bash -c "python3 \'${item.path}\'; exec bash" || '
                  'konsole -e bash -c "python3 \'${item.path}\'; exec bash" || '
                  'xterm -e "python3 \'${item.path}\'; exec bash"';
        } else {
          // Default to viewing the file with less
          command = 'ptyxis --new-window --working-directory "$dirname" --command "less \'${item.path}\'" || '
                  'gnome-terminal -- bash -c "less \'${item.path}\'; exec bash" || '
                  'xfce4-terminal -- bash -c "less \'${item.path}\'; exec bash" || '
                  'konsole -e bash -c "less \'${item.path}\'; exec bash" || '
                  'xterm -e "less \'${item.path}\'; exec bash"';
        }
      }
      
      // Execute the command using a shell 
      await Process.run('sh', ['-c', command]);
      
      // Don't check exit code as we're using fallbacks with ||
      // Show a snackbar to confirm
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Opened in terminal: ${item.name}',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to open in terminal: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  // Add a helper method to check if a file or directory exists
  Future<bool> _fileExists(String path) async {
    try {
      return await File(path).exists() || await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }

  // Optimize the _getItemsInSelectionArea method
  Set<String> _getItemsInSelectionArea(Rect selectionRect) {
    final Set<String> itemsInRect = {};
    
    if (selectionRect == Rect.zero) {
      return itemsInRect;
    }
    
    // Ensure we have updated item positions
    for (final item in _items) {
      final rect = _itemPositions[item.path];
      if (rect != null && rect != Rect.zero && rect.overlaps(selectionRect)) {
        itemsInRect.add(item.path);
      }
    }
    
    return itemsInRect;
  }
  
  // Ensure selection rectangle is properly calculated
  Rect _getSelectionRect() {
    if (_dragStartPosition == null || _dragEndPosition == null) {
      return Rect.zero;
    }
    
    final double left = min(_dragStartPosition!.dx, _dragEndPosition!.dx);
    final double top = min(_dragStartPosition!.dy, _dragEndPosition!.dy);
    final double right = max(_dragStartPosition!.dx, _dragEndPosition!.dx);
    final double bottom = max(_dragStartPosition!.dy, _dragEndPosition!.dy);
    
    // Ensure the rectangle has non-zero width and height
    final width = max(right - left, 1.0);
    final height = max(bottom - top, 1.0);
    
    return Rect.fromLTWH(left, top, width, height);
  }
  
  // Method to register item positions for hit testing during drag selection
  void _registerItemPosition(String path, Rect position) {
    _itemPositions[path] = position;
  }
  
  // Clean up after drag selection
  void _cleanupDragSelection() {
    if (!mounted) return;  // Add mounted check to prevent setState on unmounted widget
    
    setState(() {
      _isDragging = false;
      _isSelectionCompleted = true;
      _mightStartDragging = false;
      _initialPanPosition = null;
      
      // Reset the drag positions
      _dragStartPosition = null;
      _dragEndPosition = null;
    });
    
    // Schedule a cleanup of the selection completed flag after the current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;  // Add mounted check to prevent operations on unmounted widget
      
      // Only continue if we're not in the middle of another drag operation
      if (!_isDragging) {
        // Do NOT clear item positions as we need them for future drag selections
        // _itemPositions.clear(); - Remove this line
        
        setState(() {
          _isSelectionCompleted = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force position update on each layout pass
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Rebuild item positions map if grid view is available
        if (_gridViewKey.currentContext?.findRenderObject() != null) {
          _updateItemPositions();
        }
      }
    });
  }

  // Helper method to update all item positions
  void _updateItemPositions() {
    // This is called to ensure positions are up to date
    // The actual updating happens in the ItemPositionTracker widgets
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        // When closing search, clear search results and text
        _searchController.clear();
        _searchResults = [];
        _isSearching = false;
      } else {
        // When activating search, focus the search field after the frame is built
        _searchController.text = '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // We need to schedule this focus request after the UI is built
          FocusScope.of(context).requestFocus(FocusNode());
        });
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      height: 36,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search in current folder...',
          prefixIcon: Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              )
            : null,
          contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade200,
        ),
        onChanged: _performSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
      ),
    );
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _searchResults = [];
        _isSearching = false;
        return;
      }
      
      _isSearching = true;
      
      // Convert to lowercase for case-insensitive search
      final String lowercaseQuery = query.toLowerCase();
      
      // Filter the items based on the search query
      _searchResults = _items.where((item) {
        final String lowercaseName = item.name.toLowerCase();
        final String lowercaseExtension = item.fileExtension.toLowerCase();
        
        // Match by name, extension, or type for more flexibility
        return lowercaseName.contains(lowercaseQuery) ||
               (item.type == FileItemType.file && lowercaseExtension.contains(lowercaseQuery)) ||
               (lowercaseQuery == 'folder' && item.type == FileItemType.directory) ||
               (lowercaseQuery == 'file' && item.type == FileItemType.file);
      }).toList();
    });
  }

  // Method to show the open with dialog
  void _showOpenWithDialog(FileItem item) {
    // Initialize the app service if needed
    final appService = Provider.of<AppService>(context, listen: false);
    if (appService.apps.isEmpty) {
      appService.init();
    }
    
    // Show the app selection dialog
    AppSelectionDialog.show(context, item.path);
  }

  // Add a method to toggle the bookmark sidebar with animation
  void _toggleBookmarkSidebar() {
    setState(() {
      _showBookmarkSidebar = !_showBookmarkSidebar;
      if (_showBookmarkSidebar) {
        _bookmarkSidebarAnimation.forward();
      } else {
        _bookmarkSidebarAnimation.reverse();
      }
    });
  }
}

// Custom painter for drawing the selection rectangle
class SelectionRectanglePainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final bool isDarkMode;
  
  SelectionRectanglePainter({
    required this.startPoint,
    required this.endPoint,
    required this.isDarkMode,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create a selection rectangle with exact start and end points
    final rect = Rect.fromPoints(startPoint, endPoint);
    
    // Fill with semi-transparent color
    final fillPaint = Paint()
      ..color = isDarkMode
          ? Colors.blue.withValues(alpha: 51, red: 33, green: 150, blue: 243)  // 0.2 * 255 = 51
          : Colors.blue.withValues(alpha: 38, red: 33, green: 150, blue: 243)  // 0.15 * 255 = 38
      ..style = PaintingStyle.fill;
    
    // Create a border with a slightly more opaque color
    final borderPaint = Paint()
      ..color = isDarkMode
          ? Colors.blue.withValues(alpha: 153, red: 33, green: 150, blue: 243)  // 0.6 * 255 = 153
          : Colors.blue.withValues(alpha: 127, red: 33, green: 150, blue: 243)  // 0.5 * 255 = 127
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw the filled rectangle first
    canvas.drawRect(rect, fillPaint);
    
    // Then draw the border on top
    canvas.drawRect(rect, borderPaint);
  }
  
  @override
  bool shouldRepaint(SelectionRectanglePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint || 
           oldDelegate.endPoint != endPoint ||
           oldDelegate.isDarkMode != isDarkMode;
  }
}

// Widget to track the position of an item and report it to parent
class ItemPositionTracker extends StatefulWidget {
  final String path;
  final Widget child;
  final Function(String, Rect) onPositionChanged;
  
  const ItemPositionTracker({
    super.key,
    required this.path,
    required this.child,
    required this.onPositionChanged,
  });
  
  @override
  State<ItemPositionTracker> createState() => _ItemPositionTrackerState();
}

class _ItemPositionTrackerState extends State<ItemPositionTracker> {
  final GlobalKey _key = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    // Schedule a post-frame callback to get the position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePosition();
    });
  }
  
  @override
  void didUpdateWidget(ItemPositionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always update position to ensure consistency
    _updatePosition();
  }
  
  @override
  void dispose() {
    // Remove this item's position when the widget is disposed
    widget.onPositionChanged(widget.path, Rect.zero);
    super.dispose();
  }
  
  void _updatePosition() {
    if (!mounted) return;
    
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.attached) {
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      final Rect rect = Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );
      
      // Always update the position to ensure selection works
      widget.onPositionChanged(widget.path, rect);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Schedule a position update when the layout happens, but don't call
    // setState as this would cause an infinite rebuild loop
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updatePosition();
      }
    });
    
    return Container(
      key: _key,
      child: widget.child,
    );
  }
}

// Custom intents for copy/cut and paste operations
class CopyIntent extends Intent {
  final bool isCut;
  
  const CopyIntent({this.isCut = false});
  const CopyIntent.cut() : isCut = true;
  const CopyIntent.copy() : isCut = false;
}

class PasteIntent extends Intent {
  const PasteIntent();
}

// Intent for zoom in/out operations
class ZoomIntent extends Intent {
  final bool zoomIn;
  
  const ZoomIntent({required this.zoomIn});
  
  bool get isZoomIn => zoomIn;
}

// Add search-related intents
class SearchIntent extends Intent {
  const SearchIntent();
}

class CloseSearchIntent extends Intent {
  const CloseSearchIntent();
} 