import 'package:flutter/material.dart';
import 'models/file_item.dart';
import 'quick_look_manager.dart';

/// Example showing how to integrate Quick Look functionality
/// This demonstrates:
/// 1. How to handle keyboard shortcuts for Quick Look
/// 2. How to add Quick Look to context menus
/// 3. How to implement spacebar shortcuts
class QuickLookExample extends StatefulWidget {
  const QuickLookExample({super.key});

  @override
  QuickLookExampleState createState() => QuickLookExampleState();
}

class QuickLookExampleState extends State<QuickLookExample> {
  // Currently selected item
  FileItem? _selectedItem;
  
  // Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();
  
  // Search field focus node (to avoid triggering quick look when typing)
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void dispose() {
    _focusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  // Handle keyboard events including quick look
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Use QuickLookManager to handle space key for quick look
    if (QuickLookManager.handleKeyEvent(
      context, 
      event, 
      _selectedItem, 
      _searchFocusNode.hasFocus
    )) {
      return KeyEventResult.handled;
    }
    
    // Add other keyboard shortcuts here as needed
    
    return KeyEventResult.ignored;
  }
  
  // Show context menu with Quick Look option
  void _showContextMenu(FileItem item, Offset position) async {
    List<PopupMenuEntry<String>> menuItems = [
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
    ];
    
    // Add Quick Look menu option using QuickLookManager
    menuItems = QuickLookManager.addQuickLookMenuOption(menuItems);
    
    // Add other menu items as needed
    menuItems.addAll([
      PopupMenuItem<String>(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy),
            SizedBox(width: 8),
            Text('Copy'),
          ],
        ),
      ),
    ]);
    
    // Show context menu
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, 
        position.dy, 
        position.dx + 1, 
        position.dy + 1
      ),
      items: menuItems,
    );
    
    // Handle menu selection
    if (result == null) return;
    
    switch (result) {
      case 'open':
        // Handle open action
        break;
      case 'quick_look':
        // Handle quick look using QuickLookManager
        if (_selectedItem != null && mounted) {
          QuickLookManager.showQuickLook(context, _selectedItem!);
        }
        break;
      case 'copy':
        // Handle copy action
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Sample file items (would normally come from your file service)
    final fileItems = [
      FileItem(
        path: '/path/to/document.txt',
        name: 'document.txt',
        type: FileItemType.file,
      ),
      FileItem(
        path: '/path/to/image.jpg',
        name: 'image.jpg',
        type: FileItemType.file,
      ),
      FileItem(
        path: '/path/to/folder',
        name: 'folder',
        type: FileItemType.directory,
      ),
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Look Example'),
        actions: [
          // Add search field with its own focus node
          Container(
            width: 200,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: ListView.builder(
          itemCount: fileItems.length,
          itemBuilder: (context, index) {
            final item = fileItems[index];
            return ListTile(
              leading: Icon(
                item.type == FileItemType.directory ? Icons.folder : Icons.insert_drive_file,
                color: item.type == FileItemType.directory ? Colors.amber : Colors.blue,
              ),
              title: Text(item.name),
              selected: _selectedItem?.path == item.path,
              onTap: () {
                setState(() {
                  _selectedItem = item;
                });
              },
              // Use GestureDetector for context menu
              onLongPress: () {
                setState(() {
                  _selectedItem = item;
                });
                // Get position from context to show menu at tap location
                final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                final RenderBox itemBox = context.findRenderObject() as RenderBox;
                final Offset position = itemBox.localToGlobal(Offset.zero, ancestor: overlay);
                _showContextMenu(item, position);
              },
            );
          },
        ),
      ),
      bottomSheet: QuickLookManager.buildKeyBindingsHelp(),
    );
  }
} 