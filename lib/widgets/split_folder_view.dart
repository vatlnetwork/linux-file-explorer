import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'file_item_widget.dart';

class SplitFolderView extends StatefulWidget {
  final List<FileItem> items;
  final Function(FileItem) onItemTap;
  final Function(FileItem) onItemDoubleTap;
  final Function(FileItem) onItemLongPress;
  final Function(FileItem, Offset) onItemRightClick;
  final FileItem? selectedItem;
  final Function() onEmptyAreaTap;
  final Function(Offset) onEmptyAreaRightClick;

  const SplitFolderView({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onItemDoubleTap,
    required this.onItemLongPress,
    required this.onItemRightClick,
    required this.selectedItem,
    required this.onEmptyAreaTap,
    required this.onEmptyAreaRightClick,
  });

  @override
  State<SplitFolderView> createState() => _SplitFolderViewState();
}

class _SplitFolderViewState extends State<SplitFolderView> {
  // Separate controllers for each panel
  late ScrollController _foldersScrollController;
  late ScrollController _filesScrollController;

  @override
  void initState() {
    super.initState();
    _foldersScrollController = ScrollController();
    _filesScrollController = ScrollController();
  }

  @override
  void dispose() {
    _foldersScrollController.dispose();
    _filesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Separate folders and files
    final folders = widget.items.where((item) => item.type == FileItemType.directory).toList();
    final files = widget.items.where((item) => item.type == FileItemType.file).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folders panel (left side)
        Expanded(
          flex: 2,
          child: _buildPanel(
            context,
            folders,
            'Folders (${folders.length})',
            Icons.folder,
            _foldersScrollController,
          ),
        ),
        // Divider
        Container(
          width: 1,
          color: Theme.of(context).dividerColor,
        ),
        // Files panel (right side)
        Expanded(
          flex: 3,
          child: _buildPanel(
            context,
            files,
            'Files (${files.length})',
            Icons.insert_drive_file,
            _filesScrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildPanel(
    BuildContext context,
    List<FileItem> panelItems,
    String title,
    IconData headerIcon,
    ScrollController scrollController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          child: Row(
            children: [
              Icon(headerIcon, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Panel content
        Expanded(
          child: GestureDetector(
            onTap: widget.onEmptyAreaTap,
            onSecondaryTapUp: (details) => widget.onEmptyAreaRightClick(details.globalPosition),
            child: panelItems.isEmpty
                ? Center(
                    child: Text(
                      'No items',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: panelItems.length,
                    itemBuilder: (context, index) {
                      final item = panelItems[index];
                      return FileItemWidget(
                        key: ValueKey(item.path),
                        item: item,
                        onTap: () => widget.onItemTap(item),
                        onDoubleTap: () => widget.onItemDoubleTap(item),
                        onLongPress: widget.onItemLongPress,
                        onRightClick: widget.onItemRightClick,
                        isSelected: widget.selectedItem?.path == item.path,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
} 