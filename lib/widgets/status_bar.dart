import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/icon_size_service.dart';
import '../services/view_mode_service.dart';
import '../models/file_item.dart';

class StatusBar extends StatelessWidget {
  final List<FileItem> items;
  final bool showIconControls;
  
  const StatusBar({
    super.key,
    required this.items,
    this.showIconControls = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final viewModeService = Provider.of<ViewModeService>(context);
    final iconSizeService = Provider.of<IconSizeService>(context);
    
    // Count folders and files
    final folderCount = items.where((item) => item.type == FileItemType.directory).length;
    final fileCount = items.length - folderCount;
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.black54 : Colors.black12,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Item counts
          Row(
            children: [
              Text(
                '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}, $fileCount ${fileCount == 1 ? 'file' : 'files'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              // Show current UI scale
              Text(
                'UI Scale: ${(viewModeService.isGrid ? iconSizeService.gridUIScale : iconSizeService.listUIScale).toStringAsFixed(2)}×',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Icon size controls
          if (showIconControls) ...[
            // Add keyboard shortcut hint
            Text(
              'Ctrl+= / Ctrl+- to resize UI',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: isDarkMode ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Size:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              tooltip: 'Decrease icon size (Ctrl+-)',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              onPressed: () {
                if (viewModeService.isGrid) {
                  iconSizeService.decreaseGridIconSize();
                } else {
                  iconSizeService.decreaseListIconSize();
                }
              },
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              tooltip: 'Increase icon size (Ctrl+=)',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              onPressed: () {
                if (viewModeService.isGrid) {
                  iconSizeService.increaseGridIconSize();
                } else {
                  iconSizeService.increaseListIconSize();
                }
              },
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
} 