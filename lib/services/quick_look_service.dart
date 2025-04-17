import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'preview_panel_service.dart';

class QuickLookService {
  final BuildContext context;
  final PreviewPanelService previewPanelService;

  QuickLookService({
    required this.context,
    required this.previewPanelService,
  });

  /// Show a quick look preview dialog for the given file item
  Future<void> showQuickLook(FileItem item) async {
    if (!previewPanelService.canPreview(item)) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => QuickLookDialog(item: item, previewPanelService: previewPanelService),
    );
  }
}

class QuickLookDialog extends StatefulWidget {
  final FileItem item;
  final PreviewPanelService previewPanelService;

  const QuickLookDialog({
    Key? key,
    required this.item,
    required this.previewPanelService,
  }) : super(key: key);

  @override
  State<QuickLookDialog> createState() => _QuickLookDialogState();
}

class _QuickLookDialogState extends State<QuickLookDialog> {
  bool _isLoading = true;
  String? _textContent;
  List<FileItem>? _directoryContent;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _textContent = null;
      _directoryContent = null;
    });

    if (widget.item.type == FileItemType.directory) {
      final content = await widget.previewPanelService.getDirectoryContent(widget.item.path);
      if (mounted) {
        setState(() {
          _directoryContent = content;
          _isLoading = false;
        });
      }
    } else if (widget.item.type == FileItemType.file) {
      final ext = widget.item.fileExtension.toLowerCase();
      
      // Handle text files
      if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
        final content = await widget.previewPanelService.getTextFileContent(widget.item.path);
        if (mounted) {
          setState(() {
            _textContent = content;
            _isLoading = false;
          });
        }
      } else {
        // For other files, there's no loading needed
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF292929) : Colors.white,
      elevation: 24,
      insetPadding: const EdgeInsets.all(40),
      child: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with file name and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF333333) : Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.black : Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForItem(widget.item),
                    color: _getColorForItem(widget.item),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
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
            
            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPreviewContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    // Directory preview
    if (widget.item.type == FileItemType.directory) {
      return _buildDirectoryPreview();
    }
    
    // File preview based on type
    final ext = widget.item.fileExtension.toLowerCase();
    
    // Image preview
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return _buildImagePreview();
    }
    
    // Text file preview
    if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return _buildTextPreview();
    }
    
    // Video preview
    if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return _buildVideoPreview();
    }
    
    // Document preview
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      return _buildDocumentPreview();
    }
    
    // Default file info
    return _buildDefaultFileInfo();
  }

  Widget _buildDirectoryPreview() {
    if (_directoryContent == null || _directoryContent!.isEmpty) {
      return const Center(
        child: Text('This folder is empty'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _directoryContent!.length,
      itemBuilder: (context, index) {
        final item = _directoryContent![index];
        return ListTile(
          leading: Icon(
            _getIconForItem(item),
            color: _getColorForItem(item),
          ),
          title: Text(item.name),
          subtitle: Text(
            item.type == FileItemType.directory
                ? 'Folder'
                : item.formattedSize,
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Image.file(
        File(widget.item.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text('Failed to load image: $error'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextPreview() {
    if (_textContent == null) {
      return const Center(
        child: Text('Failed to load text content'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _textContent!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade300
              : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(widget.item.name),
          const SizedBox(height: 8),
          Text('Size: ${widget.item.formattedSize}'),
          Text('Modified: ${widget.item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          const Text(
            'Video preview is not supported yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview() {
    IconData iconData;
    Color iconColor;
    String fileType;
    
    final ext = widget.item.fileExtension.toLowerCase();
    if (['.pdf'].contains(ext)) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
      fileType = 'PDF Document';
    } else if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description;
      iconColor = Colors.blue;
      fileType = 'Word Document';
    } else if (['.xls', '.xlsx'].contains(ext)) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
      fileType = 'Spreadsheet';
    } else if (['.ppt', '.pptx'].contains(ext)) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
      fileType = 'Presentation';
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.blue;
      fileType = 'Document';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            widget.item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(fileType),
          Text('Size: ${widget.item.formattedSize}'),
          Text('Modified: ${widget.item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          const Text(
            'Full document preview is not supported yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultFileInfo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForItem(widget.item),
            size: 64,
            color: _getColorForItem(widget.item),
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Type: ${widget.item.fileExtension.toUpperCase().replaceFirst('.', '')} File'),
          Text('Size: ${widget.item.formattedSize}'),
          Text('Modified: ${widget.item.formattedModifiedTime}'),
        ],
      ),
    );
  }

  IconData _getIconForItem(FileItem item) {
    if (item.type == FileItemType.directory) {
      return Icons.folder;
    }

    final ext = item.fileExtension.toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return Icons.movie;
    } else if (['.mp3', '.wav', '.ogg', '.flac'].contains(ext)) {
      return Icons.music_note;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx', '.csv'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['.zip', '.rar', '.tar', '.gz'].contains(ext)) {
      return Icons.archive;
    }
    
    return Icons.insert_drive_file;
  }

  Color _getColorForItem(FileItem item) {
    if (item.type == FileItemType.directory) {
      return Colors.amber;
    }

    final ext = item.fileExtension.toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Colors.blue;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return Colors.red;
    } else if (['.mp3', '.wav', '.ogg', '.flac'].contains(ext)) {
      return Colors.purple;
    } else if (['.pdf'].contains(ext)) {
      return Colors.red;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Colors.blue;
    } else if (['.xls', '.xlsx', '.csv'].contains(ext)) {
      return Colors.green;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Colors.orange;
    } else if (['.zip', '.rar', '.tar', '.gz'].contains(ext)) {
      return Colors.brown;
    }
    
    return Colors.blueGrey;
  }
} 