import 'package:flutter/material.dart';

class BreadcrumbBar extends StatelessWidget {
  final String currentPath;
  final Function(String) onPathSelected;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const BreadcrumbBar({
    super.key,
    required this.currentPath,
    required this.onPathSelected,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pathParts = currentPath.split('/').where((part) => part.isNotEmpty).toList();
    
    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: 'Back',
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: onForward,
            tooltip: 'Forward',
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildBreadcrumbItem('/', 'Root', onPathSelected),
                  ...pathParts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final part = entry.value;
                    final path = '/${pathParts.sublist(0, index + 1).join('/')}';
                    return _buildBreadcrumbItem(path, part, onPathSelected);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String path, String name, Function(String) onPathSelected) {
    return GestureDetector(
      onTap: () => onPathSelected(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(
              Icons.chevron_right,
              size: 16.0,
            ),
          ],
        ),
      ),
    );
  }
} 