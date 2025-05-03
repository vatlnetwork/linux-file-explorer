import 'dart:io';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import 'audio_player_widget.dart';

class QuickLookDialog extends StatefulWidget {
  final FileItem item;
  
  const QuickLookDialog({
    super.key, 
    required this.item,
  });

  @override
  State<QuickLookDialog> createState() => _QuickLookDialogState();
}

class _QuickLookDialogState extends State<QuickLookDialog> {
  bool _isLoading = true;
  String? _textContent;
  
  @override
  void initState() {
    super.initState();
    debugPrint('QuickLookDialog: Initializing for file ${widget.item.path}');
    debugPrint('QuickLookDialog: File extension: ${widget.item.fileExtension}');
    debugPrint('QuickLookDialog: File type: ${widget.item.type}');
    _loadPreview();
  }
  
  Future<void> _loadPreview() async {
    if (widget.item.type == FileItemType.file) {
      final ext = widget.item.fileExtension.toLowerCase();
      
      // Load text content for text files
      if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
        try {
          final file = File(widget.item.path);
          if (await file.exists()) {
            final content = await file.readAsString();
            setState(() {
              _textContent = content;
              _isLoading = false;
            });
          } else {
            setState(() {
              _textContent = "File not found";
              _isLoading = false;
            });
          }
        } catch (e) {
          setState(() {
            _textContent = "Error loading file: $e";
            _isLoading = false;
          });
        }
      } else {
        // For other file types, just stop loading
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, 
          height: MediaQuery.of(context).size.height * 0.8,
          color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildPreviewContent()),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.item.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
  
  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final ext = widget.item.fileExtension.toLowerCase();
    debugPrint('QuickLookDialog: File extension detected: $ext');
    
    // Image preview
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      debugPrint('QuickLookDialog: Detected as image file');
      return _buildImagePreview();
    }
    
    // Text file preview
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      debugPrint('QuickLookDialog: Detected as text file');
      return _buildTextPreview();
    }
    
    // Video preview
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      debugPrint('QuickLookDialog: Detected as video file');
      return _buildVideoPreview();
    }
    
    // PDF preview
    else if (['.pdf'].contains(ext)) {
      debugPrint('QuickLookDialog: Detected as PDF file');
      return _buildPdfPreview();
    }
    
    // Audio preview
    else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      debugPrint('QuickLookDialog: Detected as audio file');
      return _buildAudioPreview();
    }
    
    // Default - show file icon and info
    debugPrint('QuickLookDialog: Using default preview');
    return _buildDefaultPreview();
  }
  
  Widget _buildImagePreview() {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(widget.item.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Could not load image', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(error.toString(), style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildTextPreview() {
    if (_textContent == null) {
      return const Center(child: Text('Unable to read text content'));
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        child: SelectableText(
          _textContent!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    // Simple video preview - in a real app, you'd use a video player
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Video Preview', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.path,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Video'),
            onPressed: () async {
              try {
                // For Linux, attempt to open with xdg-open
                if (Platform.isLinux) {
                  final result = await Process.run('xdg-open', [widget.item.path]);
                  if (result.exitCode != 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${result.stderr}')),
                      );
                    }
                  }
                } 
                // For Windows
                else if (Platform.isWindows) {
                  await Process.run('start', [widget.item.path], runInShell: true);
                } 
                // For macOS
                else if (Platform.isMacOS) {
                  await Process.run('open', [widget.item.path]);
                } 
                else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Platform not supported')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening video: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPdfPreview() {
    // Simple PDF preview - in a real app, you'd use a PDF viewer
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 100, color: Colors.red[400]),
          const SizedBox(height: 24),
          Text(
            'PDF Preview', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.path,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open PDF'),
            onPressed: () async {
              try {
                // For Linux, attempt to open with xdg-open
                if (Platform.isLinux) {
                  final result = await Process.run('xdg-open', [widget.item.path]);
                  if (result.exitCode != 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${result.stderr}')),
                      );
                    }
                  }
                } 
                // For Windows
                else if (Platform.isWindows) {
                  await Process.run('start', [widget.item.path], runInShell: true);
                } 
                // For macOS
                else if (Platform.isMacOS) {
                  await Process.run('open', [widget.item.path]);
                } 
                else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Platform not supported')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening PDF: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAudioPreview() {
    debugPrint('QuickLookDialog: Building audio preview for ${widget.item.path}');
    return Center(
      child: AudioPlayerWidget(
        audioFile: widget.item,
        darkMode: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }
  
  Widget _buildDefaultPreview() {
    IconData iconData;
    Color iconColor;
    
    final ext = widget.item.fileExtension.toLowerCase();
    if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      iconData = Icons.archive;
      iconColor = Colors.amber;
    } else if (['.exe', '.sh', '.bat'].contains(ext)) {
      iconData = Icons.terminal;
      iconColor = Colors.purple;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 100, color: iconColor),
          const SizedBox(height: 24),
          Text(
            widget.item.name, 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Type: ${widget.item.fileExtension.toUpperCase().replaceAll('.', '')} File',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${widget.item.formattedSize}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Modified: ${widget.item.formattedModifiedTime}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
} 