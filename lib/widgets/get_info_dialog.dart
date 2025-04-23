import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class GetInfoDialog extends StatelessWidget {
  final FileItem item;
  
  const GetInfoDialog({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    item.type == FileItemType.directory ? Icons.folder : Icons.insert_drive_file,
                    size: 24,
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview section
                      if (item.type == FileItemType.file) ...[
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getIconForFile(item),
                                size: 64,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // General section
                      _buildSection(
                        title: 'General',
                        children: [
                          _buildInfoRow('Kind', _getKindDescription(item)),
                          _buildInfoRow('Size', item.formattedSize),
                          _buildInfoRow('Where', p.dirname(item.path)),
                          _buildInfoRow('Created', item.formattedCreationTime),
                          _buildInfoRow('Modified', item.formattedModifiedTime),
                          if (item.whereFrom != null)
                            _buildInfoRow('Where from', item.whereFrom!),
                        ],
                      ),
                      
                      // More Info section
                      if (item.type == FileItemType.file) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'More Info',
                          children: [
                            _buildInfoRow('File extension', item.fileExtension),
                            _buildInfoRow('File name', p.basename(item.path)),
                            _buildInfoRow('Full path', item.path),
                          ],
                        ),
                      ],
                      
                      // Permissions section
                      const SizedBox(height: 16),
                      _buildSection(
                        title: 'Sharing & Permissions',
                        children: [
                          _buildInfoRow('Owner', 'You'),
                          _buildInfoRow('Access', 'Read & Write'),
                          _buildInfoRow('Sharing', 'Not shared'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getKindDescription(FileItem item) {
    if (item.type == FileItemType.directory) {
      return 'Folder';
    }
    
    final ext = item.fileExtension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return 'Image';
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return 'Video';
    } else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      return 'Audio';
    } else if (['.pdf'].contains(ext)) {
      return 'PDF Document';
    } else if (['.doc', '.docx'].contains(ext)) {
      return 'Word Document';
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return 'Excel Spreadsheet';
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return 'PowerPoint Presentation';
    } else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return 'Text Document';
    } else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      return 'Compressed Archive';
    } else {
      return '${ext.toUpperCase().replaceAll('.', '')} File';
    }
  }
  
  IconData _getIconForFile(FileItem item) {
    final ext = item.fileExtension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return Icons.video_library;
    } else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      return Icons.audiotrack;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return Icons.text_snippet;
    } else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }
} 