import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileItemWidget extends StatelessWidget {
  final FileItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onLongPress;

  const FileItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withAlpha(25) : null,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.type == FileItemType.directory ? Icons.folder : Icons.insert_drive_file,
              size: 48.0,
              color: item.type == FileItemType.directory 
                ? theme.colorScheme.primary 
                : theme.colorScheme.secondary,
            ),
            const SizedBox(height: 8.0),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 