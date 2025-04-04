import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/file_item_widget.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/bookmark_sidebar.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final FileService _fileService = FileService();
  
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

  @override
  void initState() {
    super.initState();
    _initHomeDirectory();
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening file: ${item.name}')),
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
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),
      items: [
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
        if (isFolder) 
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
      ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark added: ${item.name}')),
        );
      }
    } else if (result == 'remove_bookmark') {
      await bookmarkService.removeBookmark(item.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bookmark removed: ${item.name}')),
        );
      }
    } else if (result == 'rename') {
      _showRenameDialog(item);
    } else if (result == 'delete') {
      _showDeleteConfirmation(item);
    }
  }

  void _showEmptySpaceContextMenu(Offset position) async {
    // Deselect any selected item when right-clicking on empty space
    setState(() {
      _selectedItem = null;
    });
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
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
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened current directory in terminal')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open terminal: $e')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opened in terminal: ${item.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open in terminal: $e')),
        );
      }
    }
  }

  void _cutItem(FileItem item) {
    setState(() {
      _clipboardItem = item;
      _isItemCut = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cut: ${item.name}')),
    );
  }

  void _copyItem(FileItem item) {
    setState(() {
      _clipboardItem = item;
      _isItemCut = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: ${item.name}')),
    );
  }

  Future<void> _pasteItem() async {
    if (_clipboardItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nothing to paste')),
      );
      return;
    }
    
    try {
      final String destinationPath = p.join(_currentPath, _clipboardItem!.name);
      final String itemName = _clipboardItem!.name; // Store the name for later use
      final String sourcePath = _clipboardItem!.path; // Store the source path for later use
      
      // Don't paste if source and destination are the same
      if (p.dirname(sourcePath) == _currentPath) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot paste to the same location')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moved: $itemName')),
          );
        }
      } else {
        // Copy operation
        await _fileService.copyFileOrDirectory(sourcePath, _currentPath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Copied: $itemName')),
          );
        }
      }
      
      // Refresh directory contents
      _loadDirectory(_currentPath);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define shortcuts for cut, copy, paste
    final Map<ShortcutActivator, Intent> shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyX, control: true): const CopyIntent.cut(),
      const SingleActivator(LogicalKeyboardKey.keyC, control: true): const CopyIntent.copy(),
      const SingleActivator(LogicalKeyboardKey.keyV, control: true): const PasteIntent(),
    };

    return PopScope(
      onPopInvokedWithResult: (bool result, _) {
        if (result) {
          _navigateBack();
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
                    ],
                  ),
                ),
              ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ThemeSwitcher(),
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
      return Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

    if (_items.isEmpty) {
      return GestureDetector(
        onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'This directory is empty',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Right-click anywhere to create new files or folders',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For non-empty directories, use a Stack with properly ordered layers for hit detection
    return Stack(
      children: [
        // Bottom layer: Context menu detector for empty spaces
        GestureDetector(
          behavior: HitTestBehavior.opaque, // Opaque to ensure it gets all tap events
          onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
          onTap: () {
            // Deselect on click in empty space
            setState(() {
              _selectedItem = null;
            });
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
        
        // Top layer: ListView with AbsorbPointer to control when events go through
        AbsorbPointer(
          absorbing: false, // Don't absorb - let events pass through to list items
          child: RefreshIndicator(
            onRefresh: () => _loadDirectory(_currentPath),
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 100),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return FileItemWidget(
                  key: ValueKey(item.path), // Add key for better identification
                  item: item,
                  onTap: () => _handleItemTap(item),
                  onDoubleTap: () => _handleItemDoubleTap(item),
                  onLongPress: _showOptionsDialog,
                  onRightClick: _showContextMenu,
                  isSelected: _selectedItem?.path == item.path,
                );
              },
            ),
          ),
        ),
      ],
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