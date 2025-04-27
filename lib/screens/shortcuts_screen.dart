import 'package:flutter/material.dart';

class ShortcutsScreen extends StatelessWidget {
  const ShortcutsScreen({super.key});

  static const routeName = '/shortcuts';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Shortcuts'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildShortcutSection(
            context,
            'Navigation',
            [
              _buildShortcutItem('Ctrl+Shift+H', 'Toggle Tab Bar'),
              _buildShortcutItem('Ctrl+O', 'Open File'),
              _buildShortcutItem('Ctrl+N', 'New Window'),
              _buildShortcutItem('Ctrl+W', 'Close Tab'),
              _buildShortcutItem('Ctrl+Tab', 'Next Tab'),
              _buildShortcutItem('Ctrl+Shift+Tab', 'Previous Tab'),
            ],
          ),
          const SizedBox(height: 24),
          _buildShortcutSection(
            context,
            'File Operations',
            [
              _buildShortcutItem('Ctrl+C', 'Copy'),
              _buildShortcutItem('Ctrl+X', 'Cut'),
              _buildShortcutItem('Ctrl+V', 'Paste'),
              _buildShortcutItem('Ctrl+A', 'Select All'),
              _buildShortcutItem('Delete', 'Delete'),
              _buildShortcutItem('F2', 'Rename'),
            ],
          ),
          const SizedBox(height: 24),
          _buildShortcutSection(
            context,
            'View',
            [
              _buildShortcutItem('Ctrl++', 'Zoom In'),
              _buildShortcutItem('Ctrl+-', 'Zoom Out'),
              _buildShortcutItem('Ctrl+0', 'Reset Zoom'),
              _buildShortcutItem('F5', 'Refresh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSection(BuildContext context, String title, List<Widget> shortcuts) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts,
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description),
        ],
      ),
    );
  }
} 