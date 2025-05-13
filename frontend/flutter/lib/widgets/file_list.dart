import 'package:flutter/material.dart';
import '../models/file_info.dart';
import '../providers/file_system_provider.dart';
import 'package:provider/provider.dart';

class FileList extends StatelessWidget {
  const FileList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileSystemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(child: Text('Error: ${provider.error}'));
        }

        return ListView.builder(
          itemCount: provider.currentFiles.length,
          itemBuilder: (context, index) {
            final file = provider.currentFiles[index];
            return ListTile(
              leading: _buildFileIcon(file),
              title: Text(file.name),
              subtitle: Text(file.size),
              onTap: () {
                if (file.isDirectory) {
                  provider.listDirectory(file.path);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFileIcon(FileInfo file) {
    if (file.isDirectory) {
      if (file.customIcon != null) {
        return Image.file(
          file.customIcon!,
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.folder);
          },
        );
      }
      return const Icon(Icons.folder);
    }
    return const Icon(Icons.insert_drive_file);
  }
} 