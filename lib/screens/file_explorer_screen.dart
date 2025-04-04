import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import '../widgets/file_item_widget.dart';
import '../widgets/theme_switcher.dart';

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
    if (item.type == FileItemType.directory) {
      _navigateToDirectory(item.path);
    } else {
      // For files, we could implement a file viewer or open with default app
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected file: ${item.name}')),
      );
    }
  }
  
  void _showContextMenu(FileItem item, Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
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
      _handleItemTap(item);
    } else if (result == 'rename') {
      _showRenameDialog(item);
    } else if (result == 'delete') {
      _showDeleteConfirmation(item);
    }
  }

  void _showEmptySpaceContextMenu(Offset position) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),
      items: [
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
      ],
    );

    if (result == 'new_folder') {
      _showCreateDialog(true);
    } else if (result == 'new_file') {
      _showCreateDialog(false);
    } else if (result == 'refresh') {
      _loadDirectory(_currentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool result, _) {
        if (result) {
          _navigateBack();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            _buildPathBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'createFile',
              onPressed: () => _showCreateDialog(false),
              tooltip: 'Create File',
              mini: true,
              child: Icon(Icons.insert_drive_file),
            ),
            SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'createFolder',
              onPressed: () => _showCreateDialog(true),
              tooltip: 'Create Folder',
              child: Icon(Icons.create_new_folder),
            ),
          ],
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
          const ThemeSwitcher(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDirectory(_currentPath),
            tooltip: 'Refresh',
          ),
        ],
      ),
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
        child: Center(
          child: Text('This directory is empty'),
        ),
      );
    }

    return GestureDetector(
      onSecondaryTapUp: (details) => _showEmptySpaceContextMenu(details.globalPosition),
      child: RefreshIndicator(
        onRefresh: () => _loadDirectory(_currentPath),
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return FileItemWidget(
              item: item,
              onTap: () => _handleItemTap(item),
              onLongPress: _showOptionsDialog,
              onRightClick: _showContextMenu,
            );
          },
        ),
      ),
    );
  }
} 