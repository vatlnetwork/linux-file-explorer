import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import 'audio_player_widget.dart';
import 'package:path/path.dart' as p;

class FilePreviewScreen extends StatefulWidget {
  final FileItem item;
  
  const FilePreviewScreen({
    super.key, 
    required this.item,
  });

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  bool _isLoading = true;
  String? _textContent;
  double _zoomLevel = 1.0;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Center(child: _buildPreviewContent()),
          ),
          if (_showControls) _buildBottomControls(),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _showControls ? Colors.black.withOpacity(0.7) : Colors.transparent,
      elevation: 0,
      title: Text(
        widget.item.name,
        style: const TextStyle(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Add share button
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            try {
              Clipboard.setData(ClipboardData(text: widget.item.path));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File path copied to clipboard')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error sharing: $e')),
              );
            }
          },
        ),
        // Add more options button
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            _showOptionsMenu();
          },
        ),
      ],
    );
  }
  
  void _showOptionsMenu() {
    final fileService = FileService();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                // For text files, we could launch an editor
                final ext = widget.item.fileExtension.toLowerCase();
                if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
                  try {
                    // For now, just demonstrate we can read and write the file
                    final file = File(widget.item.path);
                    String contents = await file.readAsString();
                    // In a real app, you would launch an editor here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Editor would open here')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot edit this file type')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy, color: Colors.white),
              title: const Text('Duplicate', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final parentDir = p.dirname(widget.item.path);
                  final fileName = widget.item.name;
                  final baseName = p.basenameWithoutExtension(fileName);
                  final extension = p.extension(fileName);
                  final newName = '${baseName}_copy$extension';
                  final newPath = p.join(parentDir, newName);
                  
                  await fileService.copyFileOrDirectory(widget.item.path, parentDir);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File duplicated: $newName')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error duplicating file: $e')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.white),
              title: const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete ${widget.item.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    await fileService.deleteFileOrDirectory(widget.item.path);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File deleted successfully')),
                    );
                    Navigator.pop(context); // Close the preview screen
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting file: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Info', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showFileInfo();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.item.name),
            _buildInfoRow('Type', widget.item.fileExtension.toUpperCase().replaceAll('.', '')),
            _buildInfoRow('Size', widget.item.formattedSize),
            _buildInfoRow('Created', widget.item.formattedCreationTime),
            _buildInfoRow('Modified', widget.item.formattedModifiedTime),
            _buildInfoRow('Path', widget.item.path),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.item.path));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Path copied to clipboard')),
              );
            },
            child: const Text('Copy Path'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    
    final ext = widget.item.fileExtension.toLowerCase();
    
    // Image preview
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return _buildImagePreview();
    }
    
    // Text file preview
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return _buildTextPreview();
    }
    
    // Video preview
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return _buildVideoPreview();
    }
    
    // PDF preview
    else if (['.pdf'].contains(ext)) {
      return _buildPdfPreview();
    }
    
    // Audio preview
    else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      return _buildAudioPreview();
    }
    
    // Default - show file icon and info
    return _buildDefaultPreview();
  }
  
  Widget _buildImagePreview() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Image.file(
        File(widget.item.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, size: 80, color: Colors.white60),
              const SizedBox(height: 16),
              Text(
                'Could not load image', 
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(), 
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildTextPreview() {
    if (_textContent == null) {
      return const Text(
        'Unable to read text content',
        style: TextStyle(color: Colors.white),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          _textContent!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14 * _zoomLevel,
          ),
        ),
      ),
    );
  }
  
  Widget _buildVideoPreview() {
    // Simple video preview - in a real app, you'd use a video player
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 320,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_outline, size: 80, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Video Preview', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[400]),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.path,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildPdfPreview() {
    // Simple PDF preview - in a real app, you'd use a PDF viewer
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf, size: 100, color: Colors.red[400]),
        const SizedBox(height: 24),
        Text(
          'PDF Viewer', 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[400]),
        ),
        const SizedBox(height: 16),
        Text(
          widget.item.path,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildAudioPreview() {
    return AudioPlayerWidget(
      audioFile: widget.item, 
      darkMode: true,
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
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, size: 100, color: iconColor),
        const SizedBox(height: 24),
        Text(
          widget.item.name, 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'Type: ${widget.item.fileExtension.toUpperCase().replaceAll('.', '')} File',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 8),
        Text(
          'Size: ${widget.item.formattedSize}',
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }
  
  Widget _buildBottomControls() {
    // File type specific controls
    final ext = widget.item.fileExtension.toLowerCase();
    
    Widget controls = Container(); // Default empty controls
    
    // Image specific controls
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      controls = _buildImageControls();
    }
    // Text file specific controls
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      controls = _buildTextControls();
    }
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: controls,
      ),
    );
  }
  
  Widget _buildImageControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.rotate_left, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rotate left')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.rotate_right, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rotate right')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in, color: Colors.white),
          onPressed: () {
            setState(() {
              _zoomLevel = _zoomLevel * 1.2;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out, color: Colors.white),
          onPressed: () {
            setState(() {
              _zoomLevel = _zoomLevel / 1.2;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit image')),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildTextControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_in, color: Colors.white),
          onPressed: () {
            setState(() {
              _zoomLevel = _zoomLevel * 1.2;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.zoom_out, color: Colors.white),
          onPressed: () {
            setState(() {
              _zoomLevel = _zoomLevel / 1.2;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit text')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.content_copy, color: Colors.white),
          onPressed: () {
            if (_textContent != null) {
              Clipboard.setData(ClipboardData(text: _textContent!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text copied to clipboard')),
              );
            }
          },
        ),
      ],
    );
  }
} 