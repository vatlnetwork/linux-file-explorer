import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../services/tags_service.dart';
import '../models/tag.dart';

class FileListTile extends StatelessWidget {
  final File file;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const FileListTile({
    super.key,
    required this.file,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(file.path);
    final fileExtension = p.extension(file.path).toLowerCase();
    final fileStats = file.statSync();
    final fileSize = _formatFileSize(fileStats.size);
    final fileModified = DateTime.fromMillisecondsSinceEpoch(
      fileStats.modified.millisecondsSinceEpoch
    );
    
    // Get tags for this file
    final tagsService = Provider.of<TagsService>(context);
    final fileTags = tagsService.getTagsForFile(file.path);

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: ListTile(
        leading: Icon(
          _getIconForFile(fileExtension),
          color: _getColorForFile(fileExtension),
        ),
        title: Text(
          fileName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File info
            Text(
              '$fileSize · Modified: ${_formatDate(fileModified)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            // Tags (if any)
            if (fileTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: fileTags.map((tag) => _buildTagChip(tag)).toList(),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildTagChip(Tag tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tag.color.withAlpha(50),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: tag.color.withAlpha(100),
          width: 0.5,
        ),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          fontSize: 10,
          color: tag.color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getIconForFile(String fileExtension) {
    switch (fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return Icons.image;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Icons.music_note;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Icons.movie;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForFile(String fileExtension) {
    switch (fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return Colors.blue;
      case '.mp3':
      case '.wav':
      case '.ogg':
        return Colors.purple;
      case '.mp4':
      case '.mov':
      case '.avi':
        return Colors.red;
      case '.pdf':
        return Colors.red;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.md':
        return Colors.blue;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Colors.green;
      case '.ppt':
      case '.pptx':
        return Colors.orange;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
} 