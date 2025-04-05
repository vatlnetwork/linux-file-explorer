import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileItemWidget extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Function(FileItem) onLongPress;
  final Function(FileItem, Offset position) onRightClick;
  final bool isSelected;

  const FileItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onRightClick,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      elevation: 0,
      color: isSelected
          ? (isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50)
          : (isDarkMode ? Color(0xFF1E1E1E) : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300)
              : (isDarkMode ? Colors.black : Colors.grey.shade200),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          // This handles right-click (secondary tap) on desktop
          onRightClick(item, details.globalPosition);
        },
        behavior: HitTestBehavior.opaque,
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: () => onLongPress(item),
          child: ListTile(
            leading: _buildLeadingIcon(),
            title: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              '${item.formattedModifiedTime}${item.formattedSize.isNotEmpty ? ' • ${item.formattedSize}' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (item.type == FileItemType.directory) {
      return Icon(Icons.folder, color: Colors.blue);
    }

    // Determine icon based on file extension
    switch (item.fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        return Icon(Icons.image, color: Colors.blue);
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.flac':
        return Icon(Icons.music_note, color: Colors.purple);
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
        return Icon(Icons.movie, color: Colors.red);
      case '.pdf':
        return Icon(Icons.picture_as_pdf, color: Colors.red);
      case '.doc':
      case '.docx':
      case '.txt':
      case '.rtf':
        return Icon(Icons.description, color: Colors.blue);
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Icon(Icons.table_chart, color: Colors.green);
      case '.ppt':
      case '.pptx':
        return Icon(Icons.slideshow, color: Colors.orange);
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        return Icon(Icons.archive, color: Colors.brown);
      default:
        return Icon(Icons.insert_drive_file, color: Colors.blueGrey);
    }
  }
} 