import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../services/bookmark_service.dart';
import '../services/notification_service.dart';
import '../services/view_mode_service.dart';
import '../services/status_bar_service.dart';
import '../services/icon_size_service.dart';
import '../widgets/file_item_widget.dart';
import '../widgets/grid_item_widget.dart';
import '../widgets/split_folder_view.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/view_mode_switcher.dart';
import '../widgets/bookmark_sidebar.dart';
import '../widgets/status_bar.dart';
import '../services/usb_drive_service.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final FileService _fileService = FileService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode(); // Add focus node for keyboard events
  
  String _currentPath = '';
  List<FileItem> _items = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  final List<String> _navigationHistory = [];
  bool _showBookmarkSidebar = true;
  FileItem? _selectedItem; // Track the currently selected item
  
  // Clipboard state
  FileItem? _clipboardItem;
  bool _isItemCut = false; // false for copy, true for cut

  // Add UsbDriveService
  final UsbDriveService _usbDriveService = UsbDriveService();

  @override
  void initState() {
    super.initState();
    _initHomeDirectory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose(); // Dispose the focus node
    super.dispose();
  }

  Future<void> _initHomeDirectory() async {
    try {
      final String homeDir = await _fileService.getHomeDirectory();
      setState(() {
        _currentPath = homeDir;
      });
      _loadDirectory(homeDir);
    } catch (e) {
      _handleError('Failed to get home directory: $e');
    }
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _fileService.listDirectory(path);
      
      setState(() {
        _items = items;
        _currentPath = path;
        _isLoading = false;
        
        // Reset selection when changing directories
        _selectedItem = null;
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
    _navigationHistory.add(_currentPath);
    _loadDirectory(path);
  }

  bool _navigateBack() {
    if (_navigationHistory.isEmpty) {
      return false;
    }
    
    final String previousPath = _navigationHistory.removeLast();
    _loadDirectory(previousPath);
    return true;
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

  void _handleItemTap(FileItem item) {
    // Single click selects the item
    setState(() {
      // If the item is already selected, deselect it
      if (_selectedItem?.path == item.path) {
        _selectedItem = null;
      } else {
        _selectedItem = item;
      }
    });
  }
  
  void _handleItemDoubleTap(FileItem item) {
    // Double click opens the item
    if (item.type == FileItemType.directory) {
      _navigateToDirectory(item.path);
    } else {
      // For files, we could implement a file viewer or open with default app
      NotificationService.showNotification(
        context,
        message: 'Opening file: ${item.name}',
        type: NotificationType.info,
      );
    }
  }

  void _showContextMenu(FileItem item, Offset position) async {
    // Select the item when right-clicked
    setState(() {
      _selectedItem = item;
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
    
    final menuItems = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'open',
        child: Row(
          children: [
            Icon(item.type == FileItemType.directory ? Icons.folder_open : Icons.open_in_new),
            SizedBox(width: 8),
            Text('Open'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'open_terminal',
        child: Row(
          children: [
            Icon(Icons.terminal),
            SizedBox(width: 8),
            Text(isFolder ? 'Open in Terminal' : 'Open with Terminal'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'cut',
        child: Row(
          children: [
            Icon(Icons.content_cut),
            SizedBox(width: 8),
            Text('Cut'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.content_copy),
            SizedBox(width: 8),
            Text('Copy'),
          ],
        ),
      ),
      const PopupMenuDivider(),
    ];
    
    // Add bookmark option for folders
    if (isFolder) {
      menuItems.add(
        PopupMenuItem<String>(
          value: isBookmarked ? 'remove_bookmark' : 'add_bookmark',
          child: Row(
            children: [
              Icon(isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add),
              SizedBox(width: 8),
              Text(isBookmarked ? 'Remove from Bookmarks' : 'Add to Bookmarks'),
            ],
          ),
        ),
      );
    }
    
    // Add unmount option for mounted drives
    if (isFolder && isMountPoint) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'unmount',
          child: Row(
            children: [
              Icon(Icons.eject, color: Colors.orange),
              SizedBox(width: 8),
              Text('Unmount Drive', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }
    
    // Add remaining common options
    menuItems.addAll([
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
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
      const PopupMenuDivider(),
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
    ]);
    
    // Add mounted check before context usage
    if (!mounted) return;
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      items: menuItems,
    );

    if (result == 'open') {
      _handleItemDoubleTap(item);
    } else if (result == 'open_terminal') {
      _openInTerminal(item);
    } else if (result == 'cut') {
      _cutItem(item);
    } else if (result == 'copy') {
      _copyItem(item);
    } else if (result == 'add_bookmark') {
      await bookmarkService.addBookmark(item);
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Bookmark added: ${item.name}',
          type: NotificationType.success,
        );
      }
    } else if (result == 'remove_bookmark') {
      await bookmarkService.removeBookmark(item.path);
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Bookmark removed: ${item.name}',
          type: NotificationType.info,
        );
      }
    } else if (result == 'unmount') {
      _showUnmountConfirmation(item);
    } else if (result == 'rename') {
      _showRenameDialog(item);
    } else if (result == 'delete') {
      _showDeleteConfirmation(item);
    } else if (result == 'properties') {
      _showPropertiesDialog(item);
    }
  }

  void _showEmptySpaceContextMenu(Offset position) async {
    // Deselect any selected item when right-clicking on empty space
    setState(() {
      _selectedItem = null;
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
    
    // Add paste option if clipboard has an item
    if (_clipboardItem != null) {
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
      PopupMenuItem<String>(
        value: 'refresh',
        child: Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 8),
            Text('Refresh'),
          ],
        ),
      ),
    ]);
    // Add mounted check before context usage
    if (!mounted) return;
    
    final result = await showMenu<String>(
      context: context,
      position: menuPosition,
      items: menuItems,
    );

    if (result == 'new_folder') {
      _showCreateDialog(true);
    } else if (result == 'new_file') {
      _showCreateDialog(false);
    } else if (result == 'paste') {
      _pasteItem();
    } else if (result == 'open_in_terminal') {
      _openCurrentDirectoryInTerminal();
    } else if (result == 'refresh') {
      _loadDirectory(_currentPath);
    }
  }

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

  void _cutItem(FileItem item) {
    setState(() {
      _clipboardItem = item;
      _isItemCut = true;
    });
    NotificationService.showNotification(
      context,
      message: 'Cut: ${item.name}',
      type: NotificationType.info,
    );
  }

  void _copyItem(FileItem item) {
    setState(() {
      _clipboardItem = item;
      _isItemCut = false;
    });
    NotificationService.showNotification(
      context,
      message: 'Copied: ${item.name}',
      type: NotificationType.info,
    );
  }

  Future<void> _pasteItem() async {
    if (_clipboardItem == null) {
      NotificationService.showNotification(
        context,
        message: 'Nothing to paste',
        type: NotificationType.warning,
      );
      return;
    }
    
    try {
      final String destinationPath = p.join(_currentPath, _clipboardItem!.name);
      final String itemName = _clipboardItem!.name; // Store the name for later use
      final String sourcePath = _clipboardItem!.path; // Store the source path for later use
      
      // Don't paste if source and destination are the same
      if (p.dirname(sourcePath) == _currentPath) {
        NotificationService.showNotification(
          context,
          message: 'Cannot paste to the same location',
          type: NotificationType.warning,
        );
        return;
      }
      
      // Check if destination already exists
      bool destinationExists = false;
      try {
        if (await File(destinationPath).exists() || await Directory(destinationPath).exists()) {
          destinationExists = true;
        }
      } catch (e) {
        // Silently handle error checking destination
        // Consider implementing proper logging in production
      }
      
      if (destinationExists) {
        // File or directory already exists, show conflict dialog
        if (!mounted) return; // Check if widget is still mounted
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
        
        if (overwrite != true) return; // User canceled or closed dialog
      }
      
      if (_isItemCut) {
        // Move operation
        await _fileService.moveFileOrDirectory(sourcePath, _currentPath);
        
        // Clear clipboard after cut-paste
        setState(() {
          _clipboardItem = null;
        });
        
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Moved: $itemName',
            type: NotificationType.success,
          );
        }
      } else {
        // Copy operation
        await _fileService.copyFileOrDirectory(sourcePath, _currentPath);
        
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Copied: $itemName',
            type: NotificationType.success,
          );
        }
      }
      
      // Refresh directory contents
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
    // Define shortcuts for cut, copy, paste
    final Map<ShortcutActivator, Intent> shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyX, control: true): const CopyIntent.cut(),
      const SingleActivator(LogicalKeyboardKey.keyC, control: true): const CopyIntent.copy(),
      const SingleActivator(LogicalKeyboardKey.keyV, control: true): const PasteIntent(),
      
      // Add zoom in/out shortcuts with more key combinations
      const SingleActivator(LogicalKeyboardKey.equal, control: true): const ZoomIntent(zoomIn: true),
      const SingleActivator(LogicalKeyboardKey.minus, control: true): const ZoomIntent(zoomIn: false),
      
      // Add numeric keypad plus/minus
      const SingleActivator(LogicalKeyboardKey.numpadAdd, control: true): const ZoomIntent(zoomIn: true),
      const SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true): const ZoomIntent(zoomIn: false),
      
      // Add alternatives for different keyboard layouts
      const SingleActivator(LogicalKeyboardKey.bracketRight, control: true): const ZoomIntent(zoomIn: true), // ] key on some layouts
      const SingleActivator(LogicalKeyboardKey.slash, control: true): const ZoomIntent(zoomIn: false), // / key on some layouts
    };

    final statusBarService = Provider.of<StatusBarService>(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // Check for Ctrl+Plus/Minus combinations directly to debug
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          
          if (isControlPressed) {
            final viewModeService = Provider.of<ViewModeService>(context, listen: false);
            final iconSizeService = Provider.of<IconSizeService>(context, listen: false);
            
            // Handle various zoom in key combinations
            if (event.logicalKey == LogicalKeyboardKey.equal || 
                event.logicalKey == LogicalKeyboardKey.numpadAdd || 
                event.logicalKey.keyLabel == '+' || 
                event.logicalKey.keyLabel == '=') {
              
              // Plus sign was pressed with Ctrl
              if (viewModeService.isGrid) {
                iconSizeService.increaseGridIconSize();
              } else {
                iconSizeService.increaseListIconSize();
              }
              
              NotificationService.showNotification(
                context,
                message: 'Zooming in UI',
                type: NotificationType.success,
                duration: const Duration(milliseconds: 500),
              );
            } 
            // Handle various zoom out key combinations
            else if (event.logicalKey == LogicalKeyboardKey.minus || 
                     event.logicalKey == LogicalKeyboardKey.numpadSubtract || 
                     event.logicalKey.keyLabel == '-') {
              
              // Minus sign was pressed with Ctrl
              if (viewModeService.isGrid) {
                iconSizeService.decreaseGridIconSize();
              } else {
                iconSizeService.decreaseListIconSize();
              }
              
              NotificationService.showNotification(
                context,
                message: 'Zooming out UI',
                type: NotificationType.success,
                duration: const Duration(milliseconds: 500),
              );
            }
          }
        }
      },
      child: PopScope(
        canPop: _navigationHistory.isEmpty,
        onPopInvokedWithResult: (didPop, __) {
          if (!didPop) {
            // If we shouldn't pop (because we can navigate back), handle it manually
            setState(() {
              _navigateBack();
            });
          }
        },
        child: Scaffold(
          body: Shortcuts(
            shortcuts: shortcuts,
            child: Actions(
              actions: {
                CopyIntent: CallbackAction<CopyIntent>(
                  onInvoke: (CopyIntent intent) {
                    if (_selectedItem == null) return null;
                    if (intent.isCut) {
                      _cutItem(_selectedItem!);
                    } else {
                      _copyItem(_selectedItem!);
                    }
                    return null;
                  },
                ),
                PasteIntent: CallbackAction<PasteIntent>(
                  onInvoke: (PasteIntent intent) {
                    _pasteItem();
                    return null;
                  },
                ),
                ZoomIntent: CallbackAction<ZoomIntent>(
                  onInvoke: (ZoomIntent intent) {
                    final viewModeService = Provider.of<ViewModeService>(context, listen: false);
                    final iconSizeService = Provider.of<IconSizeService>(context, listen: false);
                    
                    // Show a notification to confirm the shortcut was triggered
                    NotificationService.showNotification(
                      context,
                      message: intent.isZoomIn ? 'Zooming in UI' : 'Zooming out UI',
                      type: NotificationType.success,
                      duration: const Duration(milliseconds: 500),
                    );
                    
                    if (intent.isZoomIn) {
                      if (viewModeService.isGrid) {
                        iconSizeService.increaseGridIconSize();
                      } else {
                        iconSizeService.increaseListIconSize();
                      }
                    } else {
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
              child: Row(
                children: [
                  if (_showBookmarkSidebar)
                    BookmarkSidebar(
                      onNavigate: _navigateToDirectory,
                      currentPath: _currentPath,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildPathBar(),
                        Expanded(
                          child: _buildContent(),
                        ),
                        // Add status bar to the bottom if enabled
                        if (statusBarService.showStatusBar)
                          StatusBar(
                            items: _items,
                            showIconControls: statusBarService.showIconControls,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPathBar() {
    final pathParts = _currentPath.split('/').where((p) => p.isNotEmpty).toList();
    
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Color(0xFF373737) 
            : Color(0xFFE3F2FD),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black54 
                : Colors.black12,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pathParts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return TextButton.icon(
                    onPressed: () {
                      _navigateToDirectory('/');
                    },
                    icon: Icon(Icons.home),
                    label: Text('Root'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.blue.shade700,
                    ),
                  );
                }
                
                final path = '/${pathParts.sublist(0, index).join('/')}';
                final isLast = index == pathParts.length;
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    TextButton(
                      onPressed: isLast ? null : () => _navigateToDirectory(path),
                      child: Text(
                        pathParts[index - 1],
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
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    final statusBarService = Provider.of<StatusBarService>(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeSwitcher(),
        const SizedBox(width: 8),
        const ViewModeSwitcher(),
        PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          offset: const Offset(0, 40),
          onSelected: (String value) {
            if (value == 'file') {
              _showCreateDialog(false);
            } else if (value == 'folder') {
              _showCreateDialog(true);
            } else if (value == 'toggle_bookmarks') {
              setState(() {
                _showBookmarkSidebar = !_showBookmarkSidebar;
              });
            } else if (value == 'refresh') {
              _loadDirectory(_currentPath);
            } else if (value == 'open_terminal') {
              _openCurrentDirectoryInTerminal();
            } else if (value == 'paste') {
              _pasteItem();
            } else if (value == 'toggle_status_bar') {
              statusBarService.toggleStatusBar();
            } else if (value == 'toggle_icon_controls') {
              statusBarService.toggleIconControls();
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
            if (_clipboardItem != null)
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
              onPressed: () => _loadDirectory(_currentPath),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text('This folder is empty'),
          ],
        ),
      );
    }

    // Get the current view mode
    final viewModeService = Provider.of<ViewModeService>(context);
    final viewMode = viewModeService.viewMode;

    // Just use a GestureDetector for right-click handling, remove the Ctrl+scroll functionality
    return GestureDetector(
      onSecondaryTapUp: (details) {
        // Handle right-click on empty space
        _showEmptySpaceContextMenu(details.globalPosition);
      },
      child: _buildViewContent(viewMode),
    );
  }

  Widget _buildViewContent(ViewMode viewMode) {
    final iconSizeService = Provider.of<IconSizeService>(context);
    
    switch (viewMode) {
      case ViewMode.grid:
        final uiScale = iconSizeService.gridUIScale;
        
        // Calculate a responsive cross axis count based on screen width and UI scale
        final screenWidth = MediaQuery.of(context).size.width;
        final minCellSize = 120.0 * uiScale; // Base cell size with scaling
        int crossAxisCount = (screenWidth / minCellSize).floor();
        crossAxisCount = crossAxisCount.clamp(2, 8); // Keep between 2 and 8 columns
        
        return GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(8.0 * uiScale),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10.0 * uiScale,
            mainAxisSpacing: 10.0 * uiScale,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return GridItemWidget(
              key: ValueKey(item.path),
              item: item,
              onTap: () => _handleItemTap(item),
              onDoubleTap: () => _handleItemDoubleTap(item),
              onLongPress: _showOptionsDialog,
              onRightClick: _showContextMenu,
              isSelected: _selectedItem?.path == item.path,
            );
          },
        );

      case ViewMode.split:
        return SplitFolderView(
          items: _items,
          onItemTap: _handleItemTap,
          onItemDoubleTap: _handleItemDoubleTap,
          onItemLongPress: _showOptionsDialog,
          onItemRightClick: _showContextMenu,
          selectedItem: _selectedItem,
          onEmptyAreaTap: () {
            setState(() {
              _selectedItem = null;
            });
          },
          onEmptyAreaRightClick: _showEmptySpaceContextMenu,
        );

      case ViewMode.list:
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(bottom: 100.0 * iconSizeService.listUIScale),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return FileItemWidget(
              key: ValueKey(item.path),
              item: item,
              onTap: () => _handleItemTap(item),
              onDoubleTap: () => _handleItemDoubleTap(item),
              onLongPress: _showOptionsDialog,
              onRightClick: _showContextMenu,
              isSelected: _selectedItem?.path == item.path,
            );
          },
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