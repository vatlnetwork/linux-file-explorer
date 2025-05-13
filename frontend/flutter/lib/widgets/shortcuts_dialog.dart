import 'package:flutter/material.dart';

class ShortcutsDialog extends StatelessWidget {
  const ShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, size: 24, color: colorScheme.primary),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts', style: TextStyle(color: colorScheme.onSurface)),
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
                _buildShortcutItem('Up Arrow', 'Move selection up', colorScheme),
                _buildShortcutItem('Down Arrow', 'Move selection down', colorScheme),
                _buildShortcutItem('Left Arrow', 'Move selection left', colorScheme),
                _buildShortcutItem('Right Arrow', 'Move selection right', colorScheme),
                _buildShortcutItem('Backspace', 'Go to parent directory', colorScheme),
                _buildShortcutItem('Alt + Up Arrow', 'Go to parent directory', colorScheme),
                _buildShortcutItem('Enter', 'Open selected item', colorScheme),
                _buildShortcutItem('Ctrl + O', 'Open selected item', colorScheme),
              ],
              colorScheme,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'Selection',
              [
                _buildShortcutItem('Ctrl + A', 'Select all items', colorScheme),
                _buildShortcutItem('Ctrl + Click', 'Select multiple items', colorScheme),
                _buildShortcutItem('Shift + Click', 'Select range of items', colorScheme),
                _buildShortcutItem('Escape', 'Clear selection', colorScheme),
              ],
              colorScheme,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'File Operations',
              [
                _buildShortcutItem('Ctrl + C', 'Copy selected items', colorScheme),
                _buildShortcutItem('Ctrl + X', 'Cut selected items', colorScheme),
                _buildShortcutItem('Ctrl + V', 'Paste items', colorScheme),
                _buildShortcutItem('Delete', 'Delete selected items', colorScheme),
                _buildShortcutItem('F2', 'Rename selected item', colorScheme),
                _buildShortcutItem('Space', 'Quick look selected item', colorScheme),
              ],
              colorScheme,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'View',
              [
                _buildShortcutItem('Ctrl + 1', 'List view', colorScheme),
                _buildShortcutItem('Ctrl + 2', 'Grid view', colorScheme),
                _buildShortcutItem('Ctrl + 3', 'Column view', colorScheme),
                _buildShortcutItem('Ctrl + +', 'Increase icon size', colorScheme),
                _buildShortcutItem('Ctrl + -', 'Decrease icon size', colorScheme),
              ],
              colorScheme,
            ),
            SizedBox(height: 16),
            _buildShortcutSection(
              'Search',
              [
                _buildShortcutItem('Ctrl + F', 'Focus search field', colorScheme),
                _buildShortcutItem('Escape', 'Clear search', colorScheme),
              ],
              colorScheme,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildShortcutSection(String title, List<Widget> items, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
} 