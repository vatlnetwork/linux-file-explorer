import 'package:flutter/material.dart';

class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, size: 24),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutSection(
              'Navigation',
              [
                _buildShortcutItem('Backspace / Alt+↑', 'Navigate up one directory'),
                _buildShortcutItem('F5', 'Refresh directory'),
                _buildShortcutItem('Ctrl+H', 'Toggle hidden files'),
                _buildShortcutItem('Ctrl+Shift+H', 'Toggle tab bar'),
              ],
              isDarkMode,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'File Operations',
              [
                _buildShortcutItem('Ctrl+C', 'Copy selected items'),
                _buildShortcutItem('Ctrl+X', 'Cut selected items'),
                _buildShortcutItem('Ctrl+V', 'Paste items'),
                _buildShortcutItem('Delete', 'Delete selected items'),
                _buildShortcutItem('Ctrl+A', 'Select all items'),
              ],
              isDarkMode,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'Search',
              [
                _buildShortcutItem('Alt+S', 'Open search dialog'),
              ],
              isDarkMode,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'Tabs',
              [
                _buildShortcutItem('Ctrl+T', 'New tab'),
              ],
              isDarkMode,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'View',
              [
                _buildShortcutItem('Space', 'Quick look selected item'),
              ],
              isDarkMode,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutSection(String title, List<Widget> shortcuts, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        ...shortcuts,
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 