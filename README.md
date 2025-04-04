# Linux File Explorer

A simple file explorer application built with Flutter for Linux systems. This app allows you to browse, create, rename, and delete files and directories in your Linux home directory.

## Features

- Navigate through your file system
- Create new files and directories
- Rename existing files and directories
- Delete files and directories
- View file details (size, modified date)
- Breadcrumb navigation support
- Right-click context menus:
  - Right-click on files/folders for options (open, rename, delete)
  - Right-click on empty space to create new files/folders
- Theme switching:
  - Toggle between system, light, and dark themes
  - Preferences are saved between sessions
- Custom theme-aware UI:
  - Custom window title bar with theme-aware controls
  - Space-efficient combined navigation and control bar
  - Consistently styled components that respond to theme changes
  - Improved visual hierarchy and readability
  - No duplicate title elements for clean design
  - Maximized content area

## Getting Started

1. Ensure you have Flutter installed and set up for Linux development
2. Clone this repository
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run -d linux
   ```

## Requirements

- Flutter SDK
- Linux environment
- Standard user permissions for accessing your files

## Note on Permissions

On Linux, the app runs with the same permissions as the user account. The app can access any files that your user account has permission to access.

## Screenshot

(Screenshots will be added once the app is running)

## License

This project is open source and available under the MIT License.
