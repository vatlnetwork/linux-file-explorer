# Linux File Explorer

A modern file explorer for Linux built with Flutter, featuring a clean UI, multiple view modes, and useful file management capabilities.

## Features

- **Multiple View Modes**: Switch between list, grid, and split views to browse files the way you prefer
- **Icon Resizing**: Hold Ctrl + Scroll wheel to resize icons and folders in both list and grid views
- **Bookmarks**: Save frequently accessed folders for quick access
- **Theme Switching**: Toggle between light and dark themes
- **File Operations**: Create, rename, delete, copy, cut, and paste files and folders
- **USB Drive Support**: Safely mount and unmount USB drives
- **Custom Window Controls**: Modern title bar with minimize, maximize, and close buttons

## How to Use

### Basic Navigation
- Click folders to navigate into them
- Use the path bar at the top to navigate to parent directories
- Right-click on empty space to access folder operations
- Right-click on files or folders to see context menu options

### Icon Resizing
1. **Hold the Ctrl key** on your keyboard
2. **Scroll up** with your mouse wheel to increase icon size
3. **Scroll down** with your mouse wheel to decrease icon size
4. Icon sizes are saved per view mode (list vs. grid)

### View Modes
Click the view mode button in the toolbar to switch between:
- List view: Compact view with details
- Grid view: Larger icons in a grid layout
- Split view: Preview pane alongside file list

### Keyboard Shortcuts
- **Ctrl+X**: Cut selected file or folder
- **Ctrl+C**: Copy selected file or folder
- **Ctrl+V**: Paste from clipboard

## Building the App

1. Clone the repository
2. Make sure you have Flutter installed
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the app in debug mode

## Dependencies

- flutter: SDK
- provider: State management
- path: Path manipulation utilities
- shared_preferences: Persistent storage
- window_manager: Custom window controls
- logging: Application logging

## License

This project is licensed under the MIT License - see the LICENSE file for details.
