// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';
import '../services/preview_panel_service.dart';
import 'preview_options_dialog.dart';
import 'quick_look_dialog.dart';
import 'tag_selector.dart';
import 'package:path/path.dart' as p;
import '../services/notification_service.dart';
import 'app_selection_dialog.dart';
import 'rename_file_dialog.dart';
import 'markup_editor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'get_info_dialog.dart';
import '../services/compression_service.dart';

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
            size: 18,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),
          ),
          if (selectedItem != null)
            IconButton(
              icon: const Icon(Icons.settings, size: 18),
              tooltip: 'Preview Options',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(const Size(24, 24)),
              onPressed: () => _showPreviewOptions(context, selectedItem),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
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
  
  void _showPreviewOptions(BuildContext context, FileItem item) async {
    final previewService = Provider.of<PreviewPanelService>(context, listen: false);
    final options = previewService.optionsManager.getOptionsForFileExtension(item.fileExtension);
    
    final result = await showDialog<PreviewOptions>(
      context: context,
      builder: (context) => PreviewOptionsDialog(
        options: options,
        fileItem: item,
      ),
    );
    
    if (result != null) {
      previewService.savePreviewOptions(result, item.fileExtension);
    }
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
    
    // Audio preview
    if (['.mp3', '.wav', '.flac'].contains(ext)) {
      return _buildAudioPreview(context, item);
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
    
    // Separate folders and files
    final folders = _directoryContent!.where((item) => item.type == FileItemType.directory).toList();
    final files = _directoryContent!.where((item) => item.type == FileItemType.file).toList();
    
    return Column(
      children: [
        // Tags section at the top
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF3C4043)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TagSelector(filePath: item.path),
            ],
          ),
        ),
        
        // Folders section
        if (folders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Folders (${folders.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final dirItem = folders[index];
                return GestureDetector(
                  onDoubleTap: () {
                    widget.onNavigate(dirItem.path);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF3C4043)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder, color: Colors.amber, size: 20),
                      title: Text(
                        dirItem.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Directory',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      onTap: () {
                        // Just select the item but don't navigate
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        
        // Files section
        if (files.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Files (${files.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final fileItem = files[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF3C4043)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 20),
                    title: Text(
                      fileItem.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      fileItem.formattedSize,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildImagePreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.imageOptions;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview at the top
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                ),
              ),
            ),
          ),
          
          // Metadata section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                
                // Common info
                if (options.showSize)
                  _buildInfoRow('Size', item.formattedSize),
                  
                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),
                  
                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  
                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),
                
                const SizedBox(height: 16),
                
                // Image specific info
                if (options.showDimensions)
                  _buildInfoRow('Dimensions', '1920 × 1080'),  // Replace with actual image dimensions
                  
                if (options.showCameraModel)
                  _buildInfoRow('Camera', 'iPhone 12 Pro'),  // Replace with actual camera model
                  
                if (options.showExposureInfo) ...[
                  _buildInfoRow('Aperture', 'f/1.6'),  // Replace with actual aperture
                  _buildInfoRow('Exposure', '1/60s'),  // Replace with actual exposure
                  _buildInfoRow('ISO', '100'),  // Replace with actual ISO
                ],
                
                if (options.showExifData) ...[
                  _buildInfoRow('Focal Length', '26mm'),  // Replace with actual focal length
                  _buildInfoRow('Flash', 'Off'),  // Replace with actual flash info
                ],
                
                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),
          
          // Quick Actions section
          if (options.showQuickActions) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              width: 268, // 300 (panel width) - 32 (total margin)
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, item),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildTextPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.defaultOptions; 
    
    if (_textContent == null) {
      return const Center(child: Text('Unable to preview text content'));
    }
    
    // Get first 500 characters or less for preview
    final previewText = _textContent!.length > 500 
        ? '${_textContent!.substring(0, 500)}...' 
        : _textContent!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content preview
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        previewText,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                        ),
                      ),
                      if (_textContent!.length > 500) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Preview only. Use Quick Look to view full content.',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Quick Actions and metadata
                if (options.showSize || options.showCreated || options.showModified || options.showQuickActions || options.showTags) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Metadata
                        if (options.showSize)
                          _buildInfoRow('Size', item.formattedSize),
                          
                        if (options.showCreated)
                          _buildInfoRow('Created', item.formattedCreationTime),
                          
                        if (options.showModified)
                          _buildInfoRow('Modified', item.formattedModifiedTime),
                          
                        if (options.showWhereFrom && item.whereFrom != null)
                          _buildInfoRow('Where from', item.whereFrom!),
                          
                        // Tags section
                        if (options.showTags) ...[
                          const SizedBox(height: 16),
                          TagSelector(filePath: item.path),
                          const SizedBox(height: 16),
                        ],
                        
                        // Quick Actions
                        if (options.showQuickActions) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? const Color(0xFF3C4043) // Dark mode background
                                  : Colors.white, // Light mode background
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildQuickActions(context, item),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildVideoPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.mediaOptions;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 220,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white70),
                ),
              ),
            ),
          ),
          
          // Metadata section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                
                // Common info
                if (options.showSize)
                  _buildInfoRow('Size', item.formattedSize),
                  
                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),
                  
                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  
                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),
                
                const SizedBox(height: 12),
                
                // Media specific info
                if (options.showDuration)
                  _buildInfoRow('Duration', '00:01:24'),  // Replace with actual duration
                  
                if (options.showCodecs)
                  _buildInfoRow('Codec', 'H.264/AAC'),  // Replace with actual codec
                  
                if (options.showBitrate)
                  _buildInfoRow('Bitrate', '8.2 Mbps'),  // Replace with actual bitrate
                  
                if (options.showDimensions)
                  _buildInfoRow('Dimensions', '1920 × 1080'),  // Replace with actual dimensions
                  
                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),
          
          // Quick Actions section
          if (options.showQuickActions) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, item),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildAudioPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.mediaOptions;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Audio icon
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                Icons.audiotrack,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
          ),
          
          // Metadata section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                
                // Common info
                if (options.showSize)
                  _buildInfoRow('Size', item.formattedSize),
                  
                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),
                  
                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  
                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),
                
                const SizedBox(height: 12),
                
                // Audio specific info
                if (options.showDuration)
                  _buildInfoRow('Duration', '00:03:45'),  // Replace with actual duration
                  
                if (options.showCodecs)
                  _buildInfoRow('Codec', 'MP3'),  // Replace with actual codec
                  
                if (options.showBitrate)
                  _buildInfoRow('Bitrate', '320 kbps'),  // Replace with actual bitrate
                  
                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),
          
          // Quick Actions section
          if (options.showQuickActions) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, item),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildDocumentPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.documentOptions;
    final ext = item.fileExtension.toLowerCase();
    
    // If it's a PDF file, show an actual PDF preview
    if (['.pdf'].contains(ext)) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF preview with a safer implementation
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
              margin: const EdgeInsets.all(16.0),
              clipBehavior: Clip.antiAlias,
              child: _buildPdfPreview(item),
            ),
            
            // Metadata section
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Common info
                  if (options.showSize)
                    _buildInfoRow('Size', item.formattedSize),
                    
                  if (options.showCreated)
                    _buildInfoRow('Created', item.formattedCreationTime),
                    
                  if (options.showModified)
                    _buildInfoRow('Modified', item.formattedModifiedTime),
                    
                  if (options.showWhereFrom && item.whereFrom != null)
                    _buildInfoRow('Where from', item.whereFrom!),
                    
                  // PDF-specific info
                  if (options.showPageCount)
                    _buildInfoRow('Pages', 'Detected from PDF'),  // In real app, get from PDF
                    
                  if (options.showAuthor)
                    _buildInfoRow('Author', 'PDF Metadata'),  // In real app, get from PDF
                    
                  // Tags section
                  if (options.showTags) ...[
                    const SizedBox(height: 16),
                    TagSelector(filePath: item.path),
                  ],
                ],
              ),
            ),
            
            // Quick Actions section
            if (options.showQuickActions) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF3C4043) // Dark mode background
                      : Colors.white, // Light mode background
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildQuickActions(context, item),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    // For other document types like docx, xlsx, etc.
    IconData iconData;
    Color iconColor;
    
    if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.orange;
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document icon
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(iconData, size: 64, color: iconColor),
            ),
          ),
          
          // Metadata section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                
                // Common info
                if (options.showSize)
                  _buildInfoRow('Size', item.formattedSize),
                  
                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),
                  
                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  
                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),
                
                const SizedBox(height: 12),
                
                // Document specific info
                if (options.showAuthor)
                  _buildInfoRow('Author', 'John Doe'),  // Replace with actual author
                  
                if (options.showPageCount)
                  _buildInfoRow('Pages', '5'),  // Replace with actual page count
                  
                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),
          
          // Quick Actions section
          if (options.showQuickActions) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, item),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  // Helper method to build PDF preview with error handling
  Widget _buildPdfPreview(FileItem item) {
    return Builder(
      builder: (context) {
        try {
          // Use a simpler fallback approach due to Linux platform compatibility issues
          return SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text(
                    'PDF Document',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        } catch (e) {
          // Fallback to simple PDF icon if viewer fails
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                const Text(
                  'PDF Document',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
      },
    );
  }
  
  Widget _buildDefaultFileInfo(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.defaultOptions;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File icon
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                Icons.insert_drive_file, 
                size: 64, 
                color: Colors.grey.shade600
              ),
            ),
          ),
          
          // Metadata section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                
                const SizedBox(height: 16),
                
                // Common info
                if (options.showSize)
                  _buildInfoRow('Size', item.formattedSize),
                  
                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),
                  
                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  
                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),
                
                // File type
                _buildInfoRow('Type', '${item.fileExtension.toUpperCase().replaceAll('.', '')} File'),
                
                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),
          
          // Quick Actions section
          if (options.showQuickActions) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context, item),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final quickActions = previewService.getQuickActionsFor(item);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (quickActions.isEmpty) {
      return const Text('No quick actions available for this file type',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic));
    }
    
    // Group actions into categories for better organization
    final commonActions = [
      QuickAction.openWith,
      QuickAction.quickLook,
    ];
    
    final editingActions = [
      QuickAction.markup,
      QuickAction.rename,
      QuickAction.extractText,
    ];
    
    final conversionActions = [
      QuickAction.createPdf,
      QuickAction.convertAudio,
      QuickAction.searchablePdf,
    ];
    
    final fileManagementActions = [
      QuickAction.duplicate,
      QuickAction.compress,
      QuickAction.compressVideo,
      QuickAction.createAlias,
      QuickAction.copyPath,
      QuickAction.getInfo,
      QuickAction.addToFavorites,
      QuickAction.revealInFolder,
    ];
    
    final mediaEditingActions = [
      QuickAction.rotate,
      QuickAction.setWallpaper,
    ];
    
    // Filter actions from each category that are available for this file
    // Exclude markup action for PDF files
    final availableCommonActions = quickActions.where((action) => commonActions.contains(action)).toList();
    final availableEditingActions = quickActions.where((action) => 
      editingActions.contains(action) && 
      !(action == QuickAction.markup && item.fileExtension.toLowerCase() == '.pdf')
    ).toList();
    final availableConversionActions = quickActions.where((action) => conversionActions.contains(action)).toList();
    final availableFileManagementActions = quickActions.where((action) => fileManagementActions.contains(action)).toList();
    final availableMediaEditingActions = quickActions.where((action) => mediaEditingActions.contains(action)).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableCommonActions.isNotEmpty) ...[
          _buildActionCategory('Common Actions', availableCommonActions, previewService, item, isDarkMode),
          const SizedBox(height: 16),
        ],
        
        if (availableEditingActions.isNotEmpty) ...[
          _buildActionCategory('Editing', availableEditingActions, previewService, item, isDarkMode),
          const SizedBox(height: 16),
        ],
        
        if (availableConversionActions.isNotEmpty) ...[
          _buildActionCategory('Convert & Create', availableConversionActions, previewService, item, isDarkMode),
          const SizedBox(height: 16),
        ],
        
        if (availableFileManagementActions.isNotEmpty) ...[
          _buildActionCategory('File Management', availableFileManagementActions, previewService, item, isDarkMode),
          const SizedBox(height: 16),
        ],
        
        if (availableMediaEditingActions.isNotEmpty) ...[
          _buildActionCategory('Media Actions', availableMediaEditingActions, previewService, item, isDarkMode),
        ],
      ],
    );
  }
  
  Widget _buildActionCategory(String title, List<QuickAction> actions, PreviewPanelService previewService, FileItem item, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        
        // Actions for this category
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions.map((action) {
            return InkWell(
              onTap: () {
                _handleQuickAction(context, action, item);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      previewService.getQuickActionIcon(action),
                      size: 16,
                      color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        previewService.getQuickActionName(action),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  void _handleQuickAction(BuildContext context, QuickAction action, FileItem item) {
    switch (action) {
      case QuickAction.rotate:
        _rotateImage(context, item);
        break;
      case QuickAction.markup:
        _openMarkupEditor(context, item);
        break;
      case QuickAction.createPdf:
        _createPdfFromFile(context, item);
        break;
      case QuickAction.searchablePdf:
        _createSearchablePdf(context, item);
        break;
      case QuickAction.openWith:
        _openFileWith(item.path);
        break;
      case QuickAction.compress:
        _compressFile(context, item);
        break;
      case QuickAction.duplicate:
        _duplicateFile(context, item);
        break;
      case QuickAction.rename:
        _renameFile(context, item);
        break;
      case QuickAction.quickLook:
        _quickLookFile(context, item);
        break;
      case QuickAction.copyPath:
        _copyFilePath(context, item);
        break;
      case QuickAction.getInfo:
        _showFileInfo(context, item);
        break;
      case QuickAction.createAlias:
        _createAlias(context, item);
        break;
      case QuickAction.addToFavorites:
        _addToFavorites(context, item);
        break;
      case QuickAction.extractText:
        _extractText(context, item);
        break;
      case QuickAction.revealInFolder:
        _revealInFolder(context, item);
        break;
      case QuickAction.convertAudio:
        _convertAudio(context, item);
        break;
      case QuickAction.compressVideo:
        _compressVideo(context, item);
        break;
      case QuickAction.extractFile:
        _extractFile(context, item);
        break;
      case QuickAction.setWallpaper:
        final previewService = Provider.of<PreviewPanelService>(context, listen: false);
        previewService.handleQuickAction(QuickAction.setWallpaper, context);
        break;
      case QuickAction.extractAudio:
        final previewService = Provider.of<PreviewPanelService>(context, listen: false);
        previewService.handleQuickAction(QuickAction.extractAudio, context);
        break;
    }
  }
  
  void _rotateImage(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context, listen: false);
    previewService.handleRotate(context);
  }
  
  void _openMarkupEditor(BuildContext context, FileItem item) async {
    // Only support markup for image files
    final ext = item.fileExtension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarkupEditor(fileItem: item),
        ),
      ).then((success) {
        if (!mounted) return;
        if (success == true) {
          // Refresh the directory view if a new file was created
          Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Markup editor only supports image files'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _createPdfFromFile(BuildContext context, FileItem item) async {
    final ext = item.fileExtension.toLowerCase();
    
    if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      try {
        // Read the text file content
        final file = File(item.path);
        final content = await file.readAsString();
        
        // Create a new PDF document
        final PdfDocument document = PdfDocument();
        
        // Add a new page
        final PdfPage page = document.pages.add();
        
        // Create a PDF font
        final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
        
        // Create a PDF brush
        final PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0));
        
        // Create a PDF string format
        final PdfStringFormat format = PdfStringFormat(
          wordWrap: PdfWordWrapType.word,
          lineSpacing: 20,
        );
        
        // Draw the text on the page
        page.graphics.drawString(
          content,
          font,
          brush: brush,
          format: format,
          bounds: Rect.fromLTWH(50, 50, page.getClientSize().width - 100, page.getClientSize().height - 100),
        );
        
        // Generate the output file path
        final outputPath = '${item.path.substring(0, item.path.lastIndexOf('.'))}.pdf';
        
        // Save the document
        final List<int> bytes = await document.save();
        await File(outputPath).writeAsBytes(bytes);
        
        // Dispose the document
        document.dispose();
        
        if (!mounted) return;
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF created successfully at $outputPath'),
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Refresh the preview panel to show the new PDF
        Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
        
      } catch (e) {
        if (!mounted) return;
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating PDF: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF creation is currently only supported for text files'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _createSearchablePdf(BuildContext context, FileItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create searchable PDF feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // New action handlers
  void _openFileWith(String filePath) {
    try {
      // Extract filename from the path
      final fileName = p.basename(filePath);
      
      // Show app selection dialog
      showDialog(
        context: context,
        builder: (context) => AppSelectionDialog(
          filePath: filePath,
          fileName: fileName,
        ),
      );
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to show open with dialog: $e',
          type: NotificationType.error,
        );
      }
    }
  }
  
  void _compressFile(BuildContext context, FileItem item) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Compress the file
      final compressionService = CompressionService();
      final outputPath = await compressionService.compressToZip(item.path);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File compressed to ${p.basename(outputPath)}'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the directory view
        Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to compress file: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _duplicateFile(BuildContext context, FileItem item) async {
    try {
      final parentDir = p.dirname(item.path);
      final fileName = item.name;
      final baseName = p.basenameWithoutExtension(fileName);
      final extension = p.extension(fileName);
      
      // Generate a new filename with "_copy" suffix
      String newPath = p.join(parentDir, '${baseName}_copy$extension');
      
      // Check if file already exists and find a unique name
      int counter = 1;
      while (await File(newPath).exists()) {
        newPath = p.join(parentDir, '${baseName}_copy($counter)$extension');
        counter++;
      }
      
      // Copy the file
      await File(item.path).copy(newPath);
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File duplicated: ${p.basename(newPath)}'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Refresh the preview panel to show the new file
      Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
      
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error duplicating file: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _renameFile(BuildContext context, FileItem item) {
    showDialog(
      context: context,
      builder: (context) => RenameFileDialog(fileItem: item),
    ).then((success) {
      if (!mounted) return;
      if (success == true) {
        // Refresh the file list if rename was successful
        Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
        
        NotificationService.showNotification(
          context,
          message: 'File renamed successfully',
          type: NotificationType.success,
        );
      }
    });
  }
  
  void _quickLookFile(BuildContext context, FileItem item) {
    debugPrint('PreviewPanel: Triggering QuickLook for ${item.path}');
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => QuickLookDialog(item: item),
    );
  }
  
  void _copyFilePath(BuildContext context, FileItem item) {
    // Using the Clipboard class to copy the path to clipboard
    Clipboard.setData(ClipboardData(text: item.path)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Path copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }
  
  void _showFileInfo(BuildContext context, FileItem item) {
    showDialog(
      context: context,
      builder: (context) => GetInfoDialog(item: item),
    );
  }
  
  void _createAlias(BuildContext context, FileItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create Alias feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _addToFavorites(BuildContext context, FileItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add to Favorites feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _extractText(BuildContext context, FileItem item) async {
    final ext = item.fileExtension.toLowerCase();
    if (!['.pdf'].contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text extraction is only supported for PDF files'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create output file path
      final outputPath = '${item.path.substring(0, item.path.lastIndexOf('.'))}.txt';
      final outputFile = File(outputPath);

      // Extract text from PDF
      final document = PdfDocument(inputBytes: File(item.path).readAsBytesSync());
      final text = StringBuffer();

      // Extract text from each page
      for (var i = 0; i < document.pages.count; i++) {
        text.writeln(PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i));
      }

      // Write text to file
      await outputFile.writeAsString(text.toString());

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text extracted to ${outputFile.path}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  void _revealInFolder(BuildContext context, FileItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reveal in Folder feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  void _convertAudio(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context, listen: false);
    previewService.handleConvertAudio(context);
  }
  
  void _compressVideo(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context, listen: false);
    previewService.handleCompressVideo(context);
  }
  
  void _extractFile(BuildContext context, FileItem item) async {
    if (!mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get the parent directory
      final parentDir = p.dirname(item.path);
      
      // Run unzip command
      final result = await Process.run('unzip', ['-o', item.path, '-d', parentDir]);
      
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File extracted to ${p.basename(parentDir)}'),
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the directory view
        Provider.of<PreviewPanelService>(context, listen: false).refreshSelectedItem();
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extract file: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 