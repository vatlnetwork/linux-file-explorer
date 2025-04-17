import 'dart:io';
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
import '../services/quick_look_service.dart'; // Add import for QuickLookService
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
      PopupMenuItem<String>(
        value: 'quick_look',
        child: Row(
          children: [
            Icon(Icons.preview),
            SizedBox(width: 8),
            Text('Quick Look (Space)'),
          ],
        ),
      ),
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
      case 'quick_look':
        _showQuickLook(item);
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
  
  Future<void> _pasteItemsToCurrentDirectory() async {
    await _pasteItemsFromInternalClipboard();
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
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // If we're searching, don't interfere with normal text input
    if (_isSearchActive && _searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
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
        return KeyEventResult.handled;
      }
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
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        // Delete selected items
        if (_selectedItemsPaths.isNotEmpty) {
          _deleteSelectedItems();
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        // Refresh directory
        _loadDirectory(_currentPath);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyC && HardwareKeyboard.instance.isControlPressed) {
        // Copy selected items
        _copySelectedItems();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyX && HardwareKeyboard.instance.isControlPressed) {
        // Cut selected items
        _cutSelectedItems();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyV && HardwareKeyboard.instance.isControlPressed) {
        // Paste items
        _pasteItemsToCurrentDirectory();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyA && HardwareKeyboard.instance.isControlPressed) {
        // Select all items
        setState(() {
          _selectedItemsPaths = _items.map((item) => item.path).toSet();
        });
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
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

  // Perform search on the current directory
  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _items.where((item) {
        return item.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  // Show app options menu
  void _showOptionsMenu(BuildContext context) {
    final viewModeService = Provider.of<ViewModeService>(context, listen: false);
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final iconSizeService = Provider.of<IconSizeService>(context, listen: false);
    final statusBarService = Provider.of<StatusBarService>(context, listen: false);
    final appService = Provider.of<AppService>(context, listen: false);
    
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      items: <PopupMenuEntry<String>>[
        // View mode submenu
        PopupMenuItem<String>(
          value: 'view_mode',
          child: Row(
            children: [
              Icon(Icons.view_list),
              SizedBox(width: 8),
              Text('View Mode'),
            ],
          ),
          onTap: () {
            // Pop this menu and show view mode submenu
            Future.delayed(const Duration(milliseconds: 10), () {
              showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(120, 100, 0, 0),
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
                    onTap: () => viewModeService.setViewMode(ViewMode.list),
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
                    onTap: () => viewModeService.setViewMode(ViewMode.grid),
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
                    onTap: () => viewModeService.setViewMode(ViewMode.split),
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
                    onTap: () => viewModeService.setViewMode(ViewMode.column),
                  ),
                ],
              );
            });
          },
        ),
        
        // Theme switcher
        PopupMenuItem<String>(
          value: 'theme',
          child: Row(
            children: [
              Icon(themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              SizedBox(width: 8),
              Text(themeService.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
            ],
          ),
          onTap: () => themeService.toggleTheme(),
        ),
        
        // Icon size submenu
        PopupMenuItem<String>(
          value: 'icon_size',
          child: Row(
            children: [
              Icon(Icons.photo_size_select_large),
              SizedBox(width: 8),
              Text('Icon Size'),
            ],
          ),
          onTap: () {
            // Pop this menu and show icon size submenu
            Future.delayed(const Duration(milliseconds: 10), () {
              showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(120, 150, 0, 0),
                items: <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'small',
                    child: Text('Small'),
                    onTap: () {
                      iconSizeService.decreaseListIconSize();
                      iconSizeService.decreaseGridIconSize();
                    },
                  ),
                  PopupMenuItem<String>(
                    value: 'medium',
                    child: Text('Medium'),
                    onTap: () => iconSizeService.resetToDefaults(),
                  ),
                  PopupMenuItem<String>(
                    value: 'large',
                    child: Text('Large'),
                    onTap: () {
                      iconSizeService.increaseListIconSize();
                      iconSizeService.increaseGridIconSize();
                    },
                  ),
                ],
              );
            });
          },
        ),
        
        // Toggle status bar
        PopupMenuItem<String>(
          value: 'status_bar',
          child: Row(
            children: [
              Icon(statusBarService.showStatusBar ? Icons.visibility_off : Icons.visibility),
              SizedBox(width: 8),
              Text(statusBarService.showStatusBar ? 'Hide Status Bar' : 'Show Status Bar'),
            ],
          ),
          onTap: () => statusBarService.toggleStatusBar(),
        ),
        
        // Toggle preview panel
        PopupMenuItem<String>(
          value: 'preview_panel',
          child: Row(
            children: [
              Icon(previewPanelService.showPreviewPanel ? Icons.info : Icons.info_outline),
              SizedBox(width: 8),
              Text(previewPanelService.showPreviewPanel ? 'Hide Preview Panel' : 'Show Preview Panel'),
            ],
          ),
          onTap: () => previewPanelService.togglePreviewPanel(),
        ),
        
        const PopupMenuDivider(),
        
        // File associations
        PopupMenuItem<String>(
          value: 'file_associations',
          child: Row(
            children: [
              Icon(Icons.link),
              SizedBox(width: 8),
              Text('File Associations'),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FileAssociationsScreen()),
            );
          },
        ),
        
        // Refresh application list
        PopupMenuItem<String>(
          value: 'refresh_apps',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Refresh App List'),
            ],
          ),
          onTap: () => appService.refreshApps(),
        ),
      ],
    );
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
                    Text('Deleting ${itemsToDelete.length} items...'),
                  ],
                ),
              );
            },
          );
        }
        
        int successCount = 0;
        List<String> errors = [];
        
        // Delete each item
        for (final item in itemsToDelete) {
          try {
            await _fileService.deleteFileOrDirectory(item.path);
            successCount++;
          } catch (e) {
            errors.add('${item.name}: $e');
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
              message: 'Deleted $successCount ${successCount == 1 ? 'item' : 'items'}',
              type: NotificationType.success,
            );
          } else {
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
                  title: Text('Delete Errors'),
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
  
  // Cut selected items to clipboard
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
      // Try to determine the default terminal
      // Common terminal emulators to check
      final List<String> terminals = [
        'gnome-terminal', 
        'konsole',
        'xfce4-terminal',
        'terminator',
        'tilix',
        'kitty',
        'alacritty',
        'xterm',
      ];
      
      // Find first available terminal
      Process.run('which', terminals).then((result) {
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
          } else {
            // For other terminals, fallback to cd command
            command.addAll([terminal, '-e', 'cd ${item.path} && bash']);
          }
          
          Process.start(command[0], command.sublist(1));
        } else {
          // Fallback to xterm if no other terminal found
          Process.start('xterm', ['-e', 'cd ${item.path} && bash']);
        }
      });
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

  // Show confirmation dialog to unmount a drive
  Future<void> _showUnmountConfirmation(FileItem item) async {
    if (item.type != FileItemType.directory) return;
    
    try {
      // Check if this is actually a mount point
      final isMountPoint = await _isDirectoryMountPoint(item.path);
      if (!isMountPoint) return;
      
      // Show confirmation dialog
      final bool confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unmount Drive'),
          content: Text('Are you sure you want to unmount the drive at "${item.path}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text('Unmount'),
            ),
          ],
        ),
      ) ?? false;
      
      if (confirmed) {
        // Show progress indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Unmounting drive...'),
                ],
              ),
            ),
          );
        }
        
        // Get the USB drive from service
        final drives = await _usbDriveService.getMountedUsbDrives();
        final drive = drives.firstWhere(
          (drive) => drive.mountPoint == item.path,
          orElse: () => UsbDrive(
            mountPoint: item.path,
            deviceName: '',
            totalBytes: 0,
            driveType: 'unknown',
          ),
        );
        
        // Perform unmount operation
        final success = await _usbDriveService.unmountDrive(item.path);
        
        // Dismiss progress dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show result notification
        if (mounted) {
          if (success) {
            NotificationService.showNotification(
              context,
              message: 'Drive unmounted successfully',
              type: NotificationType.success,
            );
            
            // Navigate up to parent directory
            if (_currentPath == item.path) {
              final directory = Directory(item.path);
              _navigateToDirectory(directory.parent.path);
            } else {
              // Refresh the current directory
              _loadDirectory(_currentPath);
            }
          } else {
            NotificationService.showNotification(
              context,
              message: 'Failed to unmount drive. Make sure no files are in use.',
              type: NotificationType.error,
            );
          }
        }
      }
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
    
    // Check if clipboard has items (we'll create a simpler implementation)
    final bool hasClipboardItems = false; // In a real implementation, this would check clipboard state
    
    // Create menu items
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
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'paste',
        enabled: hasClipboardItems,
        child: Row(
          children: [
            Icon(Icons.paste, color: hasClipboardItems ? null : Colors.grey),
            SizedBox(width: 8),
            Text('Paste', style: TextStyle(color: hasClipboardItems ? null : Colors.grey)),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'select_all',
        child: Row(
          children: [
            Icon(Icons.select_all),
            SizedBox(width: 8),
            Text('Select All'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'sort_by',
        child: Row(
          children: [
            Icon(Icons.sort),
            SizedBox(width: 8),
            Text('Sort By'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'view_options',
        child: Row(
          children: [
            Icon(Icons.view_list),
            SizedBox(width: 8),
            Text('View Options'),
          ],
        ),
      ),
    ];
    
    // Show context menu
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
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
        // Paste would be handled here in a real implementation
        break;
      case 'select_all':
        _selectAllItems();
        break;
      case 'sort_by':
        _handleSortByOptions(position);
        break;
      case 'view_options':
        _handleViewOptions();
        break;
    }
  }
  
  // Handle creating a new folder
  void _handleCreateNewFolder() {
    // In a real implementation, this would show a dialog to create a new folder
    print('Create new folder in: $_currentPath');
  }
  
  // Handle creating a new file
  void _handleCreateNewFile() {
    // In a real implementation, this would show a dialog to create a new file
    print('Create new file in: $_currentPath');
  }
  
  // Select all items in the current directory
  void _selectAllItems() {
    // In a real implementation, this would select all items in the current directory
    print('Select all items in directory: $_currentPath');
  }
  
  // Handle showing sort options
  void _handleSortByOptions(Offset position) {
    // In a full implementation, this would show a submenu with sort options
    print('Show sort options');
  }
  
  // Handle showing view options
  void _handleViewOptions() {
    // In a full implementation, this would show view options dialog or menu
    print('Show view options');
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkService = Provider.of<BookmarkService>(context);
    final viewModeService = Provider.of<ViewModeService>(context);
    final statusBarService = Provider.of<StatusBarService>(context);
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final iconSizeService = Provider.of<IconSizeService>(context);
    
    // Listen for animation changes
    if (previewPanelService.showPreviewPanel && _previewPanelAnimation.isDismissed) {
      _previewPanelAnimation.forward();
    } else if (!previewPanelService.showPreviewPanel && _previewPanelAnimation.isCompleted) {
      _previewPanelAnimation.reverse();
    }
    
    // Listen for bookmark sidebar changes
    if (_showBookmarkSidebar && _bookmarkSidebarAnimation.isDismissed) {
      _bookmarkSidebarAnimation.forward();
    } else if (!_showBookmarkSidebar && _bookmarkSidebarAnimation.isCompleted) {
      _bookmarkSidebarAnimation.reverse();
    }
    
    // Get selected items for the status bar
    final List<FileItem> selectedItems = _selectedItemsPaths.isNotEmpty 
      ? _items.where((item) => _selectedItemsPaths.contains(item.path)).toList() 
      : [];
    
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Row(
                children: [
                  // Bookmark sidebar with animation
                  AnimatedBuilder(
                    animation: _bookmarkSidebarAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: _bookmarkSidebarAnimation.value * 200,
                        child: _showBookmarkSidebar ? BookmarkSidebar(
                          onNavigate: _navigateToDirectory,
                          currentPath: _currentPath,
                        ) : null,
                      );
                    },
                  ),
                  // Main content area
                  Expanded(
                    child: _buildMainContentArea(
                      viewModeService, 
                      iconSizeService, 
                      previewPanelService,
                    ),
                  ),
                  // Preview panel with animation
                  AnimatedBuilder(
                    animation: _previewPanelAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: _previewPanelAnimation.value * 300,
                        child: previewPanelService.showPreviewPanel ? PreviewPanel(
                          onNavigate: _navigateToDirectory,
                        ) : null,
                      );
                    },
                  ),
                ],
              ),
            ),
            // Status bar at the bottom
            if (statusBarService.showStatusBar)
              StatusBar(
                items: selectedItems.isEmpty ? _items : selectedItems,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final appService = Provider.of<AppService>(context);
    final previewPanelService = Provider.of<PreviewPanelService>(context);
    
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
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
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade300 
                    : Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Linux File Explorer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
            color: Theme.of(context).dividerColor,
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
          // Search button and field
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _isSearching = false;
                  _searchResults.clear();
                } else {
                  _searchFocusNode.requestFocus();
                }
              });
            },
            tooltip: _isSearchActive ? 'Close Search' : 'Search',
            iconSize: 20,
          ),
          if (_isSearchActive)
            Container(
              width: 200,
              height: 30,
              margin: EdgeInsets.only(right: 8.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _performSearch(value);
                  } else {
                    setState(() {
                      _isSearching = false;
                      _searchResults.clear();
                    });
                  }
                },
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
          // Settings/options menu
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
            tooltip: 'Options',
            iconSize: 20,
          ),
          // Window title action buttons
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () => windowManager.minimize(),
            tooltip: 'Minimize',
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square),
            onPressed: () async {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            iconSize: 20,
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => windowManager.close(),
            tooltip: 'Close',
            iconSize: 20,
            color: Colors.red,
          ),
        ],
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

    // Show search results if searching
    final items = _isSearching ? _searchResults : _items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.folder_open,
              color: Theme.of(context).disabledColor,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              _isSearching ? 'No search results found' : 'This folder is empty',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Display files according to the selected view mode
    switch (viewModeService.viewMode) {
      case ViewMode.list:
        return _buildListView(items, iconSizeService);
      case ViewMode.grid:
        return _buildGridView(items, iconSizeService);
      case ViewMode.split:
        return _buildDetailsView(items, iconSizeService);
      case ViewMode.column:
        return ColumnViewWidget(
          currentPath: _currentPath,
          items: items,
          onNavigate: _navigateToDirectory,
          onItemTap: _selectItem,
          onItemDoubleTap: _handleItemDoubleTap,
          onItemLongPress: (item) => _showContextMenu(item, Offset.zero),
          onItemRightClick: _showContextMenu,
          selectedItemsPaths: _selectedItemsPaths,
          onEmptyAreaTap: () => setState(() => _selectedItemsPaths = {}),
          onEmptyAreaRightClick: _showEmptyAreaContextMenu,
        );
      default:
        return _buildListView(items, iconSizeService);
    }
  }

  // Implement the view builders
  Widget _buildListView(List<FileItem> items, IconSizeService iconSizeService) {
    return GestureDetector(
      onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(details.globalPosition),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedItemsPaths.contains(item.path);
          
          return FileItemWidget(
            key: ValueKey(item.path),
            item: item,
            isSelected: isSelected,
            onTap: (item, isMultiSelect) => _selectItem(item, isMultiSelect),
            onDoubleTap: () => _handleItemDoubleTap(item),
            onLongPress: (item) => _showContextMenu(item, Offset.zero),
            onRightClick: (item, position) => _showContextMenu(item, position),
          );
        },
      ),
    );
  }
  
  Widget _buildGridView(List<FileItem> items, IconSizeService iconSizeService) {
    // Calculate how many items can fit in a row based on current width
    final int crossAxisCount = (MediaQuery.of(context).size.width / 120).floor().clamp(2, 8);
    
    return GestureDetector(
      onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(details.globalPosition),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.9,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = _selectedItemsPaths.contains(item.path);
          
          return GridItemWidget(
            key: ValueKey(item.path),
            item: item,
            isSelected: isSelected,
            onTap: _selectItem,
            onDoubleTap: () => _handleItemDoubleTap(item),
            onLongPress: (item) => _showContextMenu(item, Offset.zero),
            onRightClick: _showContextMenu,
          );
        },
      ),
    );
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
}