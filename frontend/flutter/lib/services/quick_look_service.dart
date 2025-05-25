import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'preview_panel_service.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../widgets/audio_player_widget.dart';

class QuickLookService {
  final BuildContext context;
  final PreviewPanelService previewPanelService;
  final _logger = Logger('QuickLookService');

  QuickLookService({required this.context, required this.previewPanelService});

  /// Show a quick look preview dialog for the given file item
  Future<void> showQuickLook(FileItem item) async {
    _logger.info('Initiating Quick Look for ${item.path}');

    if (!previewPanelService.canPreview(item)) {
      _logger.info('Cannot preview this file type');
      return;
    }

    _logger.info('Showing dialog for ${item.name}');
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder:
          (context, animation, secondaryAnimation) => QuickLookDialog(
            item: item,
            previewPanelService: previewPanelService,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
    _logger.info('Dialog closed');
  }
}

class QuickLookDialog extends StatefulWidget {
  final FileItem item;
  final PreviewPanelService previewPanelService;

  const QuickLookDialog({
    super.key,
    required this.item,
    required this.previewPanelService,
  });

  @override
  State<QuickLookDialog> createState() => _QuickLookDialogState();
}

class _QuickLookDialogState extends State<QuickLookDialog> {
  bool _isLoading = true;
  String? _textContent;
  List<FileItem>? _directoryContent;
  late FileItem _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _loadPreview();
  }

  void _handleFileChanged(FileItem newFile) {
    setState(() {
      _currentItem = newFile;
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isLoading = true;
      _textContent = null;
      _directoryContent = null;
    });

    if (widget.item.type == FileItemType.directory) {
      final content = await widget.previewPanelService.getDirectoryContent(
        widget.item.path,
      );
      if (mounted) {
        setState(() {
          _directoryContent = content;
          _isLoading = false;
        });
      }
    } else if (widget.item.type == FileItemType.file) {
      final ext = widget.item.fileExtension.toLowerCase();

      if ([
        '.txt',
        '.md',
        '.json',
        '.yaml',
        '.yml',
        '.xml',
        '.html',
        '.css',
        '.js',
      ].contains(ext)) {
        final content = await widget.previewPanelService.getTextFileContent(
          widget.item.path,
        );
        if (mounted) {
          setState(() {
            _textContent = content;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);
    final ext = _currentItem.fileExtension.toLowerCase();
    final isAudioFile = ['.mp3', '.wav', '.ogg', '.flac'].contains(ext);

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF292929) : Colors.white,
      elevation: 24,
      insetPadding: const EdgeInsets.all(40),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Container(
        width: 800,
        height: 600,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDarkMode ? const Color(0xFF333333) : Colors.grey.shade100,
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
                    _getIconForItem(_currentItem),
                    color: _getColorForItem(_currentItem),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentItem.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAudioFile)
                          Text(
                            'Now Playing',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                      ],
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
            Expanded(
              child:
                  _isLoading
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
    if ([
      '.txt',
      '.md',
      '.json',
      '.yaml',
      '.yml',
      '.xml',
      '.html',
      '.css',
      '.js',
    ].contains(ext)) {
      return _buildTextPreview();
    }

    // Video preview
    if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return _buildVideoPreview();
    }

    // Audio preview
    if (['.mp3', '.wav', '.ogg', '.flac'].contains(ext)) {
      return _buildAudioPreview();
    }

    // Document preview
    if ([
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
    ].contains(ext)) {
      return _buildDocumentPreview();
    }

    // Default file info
    return _buildDefaultFileInfo();
  }

  Widget _buildDirectoryPreview() {
    if (_directoryContent == null || _directoryContent!.isEmpty) {
      return const Center(child: Text('This folder is empty'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _directoryContent!.length,
      itemBuilder: (context, index) {
        final item = _directoryContent![index];
        return ListTile(
          leading: Icon(_getIconForItem(item), color: _getColorForItem(item)),
          title: Text(item.name),
          subtitle: Text(
            item.type == FileItemType.directory ? 'Folder' : item.formattedSize,
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
              const Icon(Icons.broken_image, size: 64, color: Colors.red),
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
      return const Center(child: Text('Failed to load text content'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _textContent!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color:
              Theme.of(context).brightness == Brightness.dark
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
          Icon(Icons.movie, size: 64, color: Colors.red),
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

  Widget _buildAudioPreview() {
    return Center(
      child: AudioPlayerWidget(
        audioFile: widget.item,
        darkMode: Theme.of(context).brightness == Brightness.dark,
        onFileChanged: _handleFileChanged,
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final ext = widget.item.fileExtension.toLowerCase();

    // If it's a PDF file, show a basic preview instead of using SfPdfViewer
    if (['.pdf'].contains(ext)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              widget.item.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('PDF Document'),
            Text('Size: ${widget.item.formattedSize}'),
            Text('Modified: ${widget.item.formattedModifiedTime}'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open with default app'),
              onPressed: () {
                // This would typically launch the file with the default app
                Navigator.of(context).pop(); // Close quick look
              },
            ),
          ],
        ),
      );
    }

    // For other document types, show file info
    IconData iconData;
    Color iconColor;
    String fileType;

    if (['.doc', '.docx'].contains(ext)) {
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
          Text(
            'Type: ${widget.item.fileExtension.toUpperCase().replaceFirst('.', '')} File',
          ),
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
