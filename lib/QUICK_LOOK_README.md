# Quick Look Feature Implementation

This document provides instructions for integrating the Quick Look feature into the Linux File Explorer application.

## Files Overview

1. `services/quick_look_service.dart` - Core service implementing the Quick Look dialog
2. `quick_look_manager.dart` - Utility class for easily integrating Quick Look across the application
3. `quick_look_example.dart` - Example implementation showing how to integrate Quick Look

## Integration Steps

### 1. Create Quick Look Service

The `QuickLookService` class is responsible for displaying the Quick Look dialog for a given file item. It uses the existing `PreviewPanelService` to handle the actual file preview logic, ensuring consistency between the Quick Look and the Preview Panel.

### 2. Add Keyboard Shortcut Support

To enable Quick Look via the spacebar:

1. Add a focus node to the main file explorer screen
2. Handle keyboard events and respond to spacebar presses:

```dart
// In your file explorer screen:
KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
  // Use QuickLookManager to handle Quick Look
  if (QuickLookManager.handleKeyEvent(
    context, 
    event, 
    _selectedItem, // Currently selected item
    _searchFocusNode.hasFocus // Whether search field has focus
  )) {
    return KeyEventResult.handled;
  }
  
  // Handle other keyboard shortcuts
  
  return KeyEventResult.ignored;
}
```

3. Wrap your main content with a `Focus` widget:

```dart
Focus(
  focusNode: _focusNode,
  autofocus: true,
  onKeyEvent: _handleKeyEvent,
  child: YourMainContentWidget(),
)
```

### 3. Add Quick Look to Context Menus

When showing a context menu for a file or folder, add a Quick Look option:

```dart
void _showContextMenu(FileItem item, Offset position) {
  List<PopupMenuEntry<String>> menuItems = [
    // Your existing menu items...
  ];
  
  // Add Quick Look menu option
  menuItems = QuickLookManager.addQuickLookMenuOption(menuItems);
  
  // Show menu...
  
  // Handle selection:
  if (result == 'quick_look') {
    QuickLookManager.showQuickLook(context, item);
  }
}
```

### 4. (Optional) Add Key Bindings Help

You can add the Quick Look key binding help to your UI by using:

```dart
QuickLookManager.buildKeyBindingsHelp()
```

This creates a widget showing the spacebar shortcut for Quick Look.

## Usage

Once integrated, users can:

1. Press the spacebar to preview the currently selected file/folder
2. Right-click and select "Quick Look" from the context menu
3. See a visual indication of the spacebar shortcut in the context menu

## Benefits

- Provides a quick way to preview files without opening them
- Familiar UX for users coming from macOS
- Uses existing preview functionality, ensuring consistent UX
- Minimal code changes required for integration

## Notes

The Quick Look feature is designed to complement the existing Preview Panel, not replace it. The Preview Panel is better for sustained viewing of files, while Quick Look is ideal for quickly checking the contents of a file before deciding whether to open it. 