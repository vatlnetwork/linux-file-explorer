import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/preview_panel_service.dart';

class PreviewPanel extends StatefulWidget {
  final Function(String) onNavigate;
  
  const PreviewPanel({
    super.key,
    required this.onNavigate,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  String? _textContent;
  List<FileItem>? _directoryContent;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Don't load preview in initState
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPreview();
  }
  
  Future<void> _loadPreview() async {
    final previewService = Provider.of<PreviewPanelService>(context);
    final selectedItem = previewService.selectedItem;
    
    if (selectedItem == null) return;
    
    setState(() {
      _isLoading = true;
      _textContent = null;
      _directoryContent = null;
    });
    
    if (selectedItem.type == FileItemType.directory) {
      final content = await previewService.getDirectoryContent(selectedItem.path);
      if (mounted) {
        setState(() {
          _directoryContent = content;
          _isLoading = false;
        });
      }
    } else if (selectedItem.type == FileItemType.file) {
      final ext = selectedItem.fileExtension.toLowerCase();
      
      // Handle text files
      if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
        final content = await previewService.getTextFileContent(selectedItem.path);
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
    return Consumer<PreviewPanelService>(
      builder: (context, previewService, _) {
        final selectedItem = previewService.selectedItem;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          width: 300,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF252525) : const Color(0xFFBBDEFB),
            border: Border(
              left: BorderSide(
                color: isDarkMode ? Colors.black : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, selectedItem),
              if (selectedItem != null) 
                Expanded(
                  child: _buildPreviewContent(context, selectedItem),
                )
              else 
                Expanded(
                  child: _buildNoSelectionView(context),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context, FileItem? selectedItem) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252525) : const Color(0xFFBBDEFB),
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
            Icons.preview,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Text(
            'Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(const Size(24, 24)),
            tooltip: 'Close preview panel',
            onPressed: () {
              Provider.of<PreviewPanelService>(context, listen: false).togglePreviewPanel();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoSelectionView(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography,
              size: 48,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No item selected',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a file or folder to preview its contents',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewContent(BuildContext context, FileItem item) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Directory preview
    if (item.type == FileItemType.directory) {
      return _buildDirectoryPreview(context, item);
    }
    
    // File preview based on type
    final ext = item.fileExtension.toLowerCase();
    
    // Image preview
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return _buildImagePreview(context, item);
    }
    
    // Text file preview
    if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return _buildTextPreview(context, item);
    }
    
    // Video preview
    if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return _buildVideoPreview(context, item);
    }
    
    // Document preview
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      return _buildDocumentPreview(context, item);
    }
    
    // Default file info
    return _buildDefaultFileInfo(context, item);
  }
  
  Widget _buildDirectoryPreview(BuildContext context, FileItem item) {
    if (_directoryContent == null) {
      return const Center(child: Text('No items in directory'));
    }
    
    if (_directoryContent!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Directory is empty', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _directoryContent!.length,
      itemBuilder: (context, index) {
        final dirItem = _directoryContent![index];
        return ListTile(
          leading: dirItem.type == FileItemType.directory
              ? const Icon(Icons.folder, color: Colors.amber)
              : const Icon(Icons.insert_drive_file, color: Colors.blue),
          title: Text(
            dirItem.name,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            dirItem.type == FileItemType.directory
                ? 'Directory'
                : dirItem.formattedSize,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          onTap: () {
            widget.onNavigate(dirItem.path);
          },
        );
      },
    );
  }
  
  Widget _buildImagePreview(BuildContext context, FileItem item) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.file(
                File(item.path),
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Could not load image', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text(error.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  );
                },
              ),
            ),
            Text(
              'Name: ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Size: ${item.formattedSize}'),
            Text('Modified: ${item.formattedModifiedTime}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextPreview(BuildContext context, FileItem item) {
    if (_textContent == null) {
      return const Center(child: Text('Unable to preview text content'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade800 
              : Colors.grey.shade200,
          child: Row(
            children: [
              const Icon(Icons.text_fields, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(_textContent!),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVideoPreview(BuildContext context, FileItem item) {
    // For now, just show file info - video previews would require a video player plugin
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_file, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Size: ${item.formattedSize}'),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          const Text(
            'Video preview is not supported yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDocumentPreview(BuildContext context, FileItem item) {
    // Simple document info preview
    IconData iconData;
    Color iconColor;
    
    final ext = item.fileExtension.toLowerCase();
    if (['.pdf'].contains(ext)) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.orange;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Size: ${item.formattedSize}'),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          const Text(
            'Full document preview is not supported yet',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDefaultFileInfo(BuildContext context, FileItem item) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('Size: ${item.formattedSize}'),
          Text('Modified: ${item.formattedModifiedTime}'),
          const SizedBox(height: 16),
          Text(
            'File type ${item.fileExtension} cannot be previewed',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
} 