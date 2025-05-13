import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'file_item_widget.dart';

class FileGridView extends StatelessWidget {
  final List<FileItem> items;
  final Set<String> selectedItems;
  final Function(FileItem) onItemTap;
  final Function(FileItem) onItemDoubleTap;
  final Function(FileItem) onItemLongPress;

  const FileGridView({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onItemTap,
    required this.onItemDoubleTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedItems.contains(item.path);
        
        return FileItemWidget(
          item: item,
          isSelected: isSelected,
          onTap: () => onItemTap(item),
          onDoubleTap: () => onItemDoubleTap(item),
          onLongPress: () => onItemLongPress(item),
        );
      },
    );
  }
} 