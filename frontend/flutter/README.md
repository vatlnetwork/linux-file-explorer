# Linux File Manager

A modern file explorer for Linux built with Flutter, featuring a clean UI, multiple view modes, and comprehensive file management capabilities.

## Features

- **Multiple View Modes**: Switch between list, grid, and split views to browse files the way you prefer
- **Smart Context Menus**: Right-click on files, folders, or empty spaces to access context-sensitive options
- **Responsive Icon Sizing**: Use Ctrl + "=" and Ctrl + "-" (or mouse wheel) to resize icons for better visibility
- **Bookmarks Sidebar**: Save and organize frequently accessed folders for quick navigation
- **Dark/Light Themes**: Toggle between dark and light modes to match your system preference
- **Complete File Operations**: Create, rename, delete, copy, cut, and paste files and folders
- **USB Drive Support**: Mount, browse, and safely unmount USB drives
- **Disk Usage Information**: View available space and usage statistics for drives
- **Customizable UI**: Adjust status bar, icon controls, and layout to suit your preferences

## Navigation and Usage

### Browsing Files
- Navigate through folders with simple clicks
- Use the path breadcrumb bar at the top to quickly jump to parent directories
- Toggle the bookmarks sidebar for quick access to favorite locations

### Context Menus
- **Right-click on files/folders**: Access operations like Open, Copy, Cut, Delete, Rename, etc.
- **Right-click on empty space**: Create new files/folders, paste items, refresh view, or open terminal
- **Right-click in empty folders**: All empty space context options remain available

### View Modes
- **List View**: Compact view with detailed file information
- **Grid View**: Visual layout with resizable icons
- **Split View**: Dual-pane layout with folders on left, files on right

### Keyboard Shortcuts
- **Ctrl+X**: Cut selected file(s) or folder(s)
- **Ctrl+C**: Copy selected file(s) or folder(s)
- **Ctrl+V**: Paste from clipboard
- **Ctrl+=**: Increase icon size (Zoom in)
- **Ctrl+-**: Decrease icon size (Zoom out)
- **Ctrl+A**: Select all items in current folder
- **Escape**: Clear current selection

### Multi-Select
- Click while holding Ctrl to select multiple items
- Select multiple items to perform bulk operations (copy, cut, delete)

## Building and Running

1. Clone the repository
2. Make sure you have Flutter installed
3. Run `flutter pub get` to install dependencies
4. Run `flutter run -d linux` to start the app on Linux

## Dependencies

- flutter: SDK
- provider: State management
- path: Path manipulation utilities
- shared_preferences: Persistent storage
- window_manager: Custom window controls
- logging: Application logging

## System Requirements

- Linux-based operating system
- Flutter environment configured for Linux desktop development

## License

This project is licensed under the MIT License - see the LICENSE file for details.
