import 'package:flutter/material.dart';
import '../models/file_item.dart';

class FileGridView extends StatefulWidget {
  const FileGridView({super.key});

  @override
  FileGridViewState createState() => FileGridViewState();
}

class FileGridViewState extends State<FileGridView> {
  // ... (existing code)

  Widget _buildItemIcon(FileItem item, double size) {
    if (item.type == FileItemType.directory) {
      // Check for special folder icon
      final specialIcon = item.specialFolderIcon;
      
      if (specialIcon != null) {
        return SizedBox(
          width: size,
          height: size,
          child: specialIcon,
        );
      }
      
      return Icon(Icons.folder, color: Colors.blue, size: size);
    }

    // For files, return a generic file icon
    return Icon(Icons.insert_drive_file, color: Colors.grey, size: size);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) => _buildItemIcon(FileItem(
        path: '',
        name: '',
        type: FileItemType.file,
      ), 24.0),
    );
  }
} 