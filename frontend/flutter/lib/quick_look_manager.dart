import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/file_item.dart';
import 'services/preview_panel_service.dart';
import 'services/quick_look_service.dart';

/// A manager class to handle Quick Look functionality throughout the application.
/// 
/// This class provides methods to:
/// 1. Handle keyboard shortcuts for Quick Look (Space key)
/// 2. Show the Quick Look dialog for a given file item
/// 3. Add Quick Look option to context menus
class QuickLookManager {
  /// Shows the Quick Look dialog for the given file item
  static void showQuickLook(BuildContext context, FileItem item) {
    final previewPanelService = Provider.of<PreviewPanelService>(context, listen: false);
    final quickLookService = QuickLookService(
      context: context,
      previewPanelService: previewPanelService,
    );
    quickLookService.showQuickLook(item);
  }

  /// Handles keyboard events for Quick Look functionality
  /// Returns true if the event was handled, false otherwise
  static bool handleKeyEvent(BuildContext context, KeyEvent event, FileItem? selectedItem, bool isInSearchField) {
    // Handle spacebar for quick look
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.space && 
        !isInSearchField && 
        selectedItem != null) {
      
      showQuickLook(context, selectedItem);
      return true;
    }
    
    return false;
  }
  
  /// Adds a Quick Look menu item to a context menu
  static List<PopupMenuEntry<String>> addQuickLookMenuOption(List<PopupMenuEntry<String>> menuItems) {
    // This method has been deprecated - Quick Look is now only available via the spacebar shortcut
    // Return the original menu items without modification
    return menuItems;
  }
  
  /// Adds a key bindings help item to the menu
  static Widget buildKeyBindingsHelp() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Look Shortcut:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text('Space',
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
              SizedBox(width: 8),
              Text('Show Quick Look for selected item'),
            ],
          ),
        ],
      ),
    );
  }
} 