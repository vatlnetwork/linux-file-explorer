// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';
import '../services/preview_panel_service.dart';
import 'preview_options_dialog.dart';
import 'tag_selector.dart';

class PreviewPanel extends StatefulWidget {
  final Function(String) onNavigate;

  const PreviewPanel({super.key, required this.onNavigate});

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
      final content = await previewService.getDirectoryContent(
        selectedItem.path,
      );
      if (mounted) {
        setState(() {
          _directoryContent = content;
          _isLoading = false;
        });
      }
    } else if (selectedItem.type == FileItemType.file) {
      final ext = selectedItem.fileExtension.toLowerCase();

      // Handle text files
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
        final content = await previewService.getTextFileContent(
          selectedItem.path,
        );
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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Calculate width based on available space, with min and max constraints
            final width = constraints.maxWidth.clamp(200.0, 400.0);

            return Container(
              width: width,
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? const Color(0xFF252525)
                        : const Color(0xFFBBDEFB),
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
                    Expanded(child: _buildPreviewContent(context, selectedItem))
                  else
                    Expanded(child: _buildNoSelectionView(context)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, FileItem? selectedItem) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            Icons.preview,
            size: 18,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Expanded(child: Container()),
          if (selectedItem != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: 'Preview Options',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tight(const Size(24, 24)),
                onPressed: () => _showPreviewOptions(context, selectedItem),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tight(const Size(24, 24)),
            tooltip: 'Close preview panel',
            onPressed: () {
              Provider.of<PreviewPanelService>(
                context,
                listen: false,
              ).togglePreviewPanel();
            },
          ),
        ],
      ),
    );
  }

  void _showPreviewOptions(BuildContext context, FileItem item) async {
    final previewService = Provider.of<PreviewPanelService>(
      context,
      listen: false,
    );
    final options = previewService.getOptionsForFileItem(item);

    final result = await showDialog<PreviewOptions>(
      context: context,
      builder:
          (context) => PreviewOptionsDialog(options: options, fileItem: item),
    );

    if (result != null) {
      await previewService.savePreviewOptionsForItem(result, item);
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
      return _buildTextPreview(context, item);
    }

    // Video preview
    if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return _buildVideoPreview(context, item);
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

    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.getOptionsForFileItem(item);

    if (_directoryContent!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Directory is empty',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Filter out hidden items if not showing them
    final filteredContent =
        options.showHiddenItems
            ? _directoryContent!
            : _directoryContent!
                .where((item) => !item.name.startsWith('.'))
                .toList();

    // Separate folders and files
    final folders =
        filteredContent
            .where((item) => item.type == FileItemType.directory)
            .toList();
    final files =
        filteredContent
            .where((item) => item.type == FileItemType.file)
            .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags section at the top
          if (options.showTags) ...[
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3C4043)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tags',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  TagSelector(filePath: item.path),
                ],
              ),
            ),
          ],

          // Folder info section
          if (options.showFolderContents) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3C4043)
                        : Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Folder Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactInfoRow('Size', item.formattedSize),
                  _buildCompactInfoRow(
                    'Items',
                    '${folders.length} folders, ${files.length} files',
                  ),
                ],
              ),
            ),
          ],

          // Folders section
          if (options.showFolderContents && folders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Folders (${folders.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3C4043)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.folder,
                        color: Colors.amber,
                        size: 20,
                      ),
                      title: Text(
                        dirItem.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: const Text(
                        'Directory',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      onTap: () {
                        // Just select the item but don't navigate
                      },
                    ),
                  ),
                );
              },
            ),
          ],

          // Files section
          if (options.showFolderContents && files.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Files (${files.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
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
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3C4043)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blue,
                      size: 20,
                    ),
                    title: Text(
                      fileItem.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    subtitle: Text(
                      fileItem.formattedSize,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.imageOptions;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate image height based on available width
        final imageHeight = (constraints.maxWidth * 0.8).clamp(150.0, 300.0);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image preview at the top
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: imageHeight,
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
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Could not load image',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Metadata section with compact layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Common info in a more compact layout
                    if (options.showSize)
                      _buildCompactInfoRow('Size', item.formattedSize),

                    if (options.showCreated)
                      _buildCompactInfoRow(
                        'Created',
                        item.formattedCreationTime,
                      ),

                    if (options.showModified)
                      _buildCompactInfoRow(
                        'Modified',
                        item.formattedModifiedTime,
                      ),

                    if (options.showWhereFrom && item.whereFrom != null)
                      _buildCompactInfoRow('Where from', item.whereFrom!),

                    const SizedBox(height: 8),

                    // Image specific info
                    if (options.showDimensions)
                      _buildCompactInfoRow(
                        'Dimensions',
                        '1920 × 1080',
                      ), // Replace with actual dimensions

                    if (options.showExifData)
                      _buildCompactInfoRow(
                        'EXIF',
                        'Available',
                      ), // Replace with actual EXIF status

                    if (options.showCameraModel)
                      _buildCompactInfoRow(
                        'Camera',
                        'Canon EOS 5D',
                      ), // Replace with actual camera model

                    if (options.showExposureInfo)
                      _buildCompactInfoRow(
                        'Exposure',
                        '1/125, f/2.8, ISO 100',
                      ), // Replace with actual exposure info
                    // Tags section
                    if (options.showTags) ...[
                      const SizedBox(height: 8),
                      TagSelector(filePath: item.path),
                    ],
                  ],
                ),
              ),

              // Remove Quick Actions section
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
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
    final previewText =
        _textContent!.length > 500
            ? '${_textContent!.substring(0, 500)}...'
            : _textContent!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content preview
            Container(
              padding: const EdgeInsets.all(8),
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
              child: Row(
                children: [
                  const Icon(Icons.text_fields, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            previewText,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade800,
                            ),
                          ),
                          if (_textContent!.length > 500) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Preview only. Use Quick Look to view full content.',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Common info in compact layout
                          if (options.showSize)
                            _buildCompactInfoRow('Size', item.formattedSize),

                          if (options.showCreated)
                            _buildCompactInfoRow(
                              'Created',
                              item.formattedCreationTime,
                            ),

                          if (options.showModified)
                            _buildCompactInfoRow(
                              'Modified',
                              item.formattedModifiedTime,
                            ),

                          if (options.showWhereFrom && item.whereFrom != null)
                            _buildCompactInfoRow('Where from', item.whereFrom!),

                          // Tags section
                          if (options.showTags) ...[
                            const SizedBox(height: 8),
                            TagSelector(filePath: item.path),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.mediaOptions;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate thumbnail size based on available width
        final thumbnailWidth = (constraints.maxWidth * 0.8).clamp(150.0, 300.0);
        final thumbnailHeight = thumbnailWidth * 0.5625; // 16:9 aspect ratio

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video thumbnail
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: thumbnailWidth,
                    height: thumbnailHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 32,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),

              // Metadata section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Common info in compact layout
                    if (options.showSize)
                      _buildCompactInfoRow('Size', item.formattedSize),

                    if (options.showCreated)
                      _buildCompactInfoRow(
                        'Created',
                        item.formattedCreationTime,
                      ),

                    if (options.showModified)
                      _buildCompactInfoRow(
                        'Modified',
                        item.formattedModifiedTime,
                      ),

                    if (options.showWhereFrom && item.whereFrom != null)
                      _buildCompactInfoRow('Where from', item.whereFrom!),

                    const SizedBox(height: 8),

                    // Media specific info
                    if (options.showDuration)
                      _buildCompactInfoRow(
                        'Duration',
                        '00:01:24',
                      ), // Replace with actual duration

                    if (options.showCodecs)
                      _buildCompactInfoRow(
                        'Codec',
                        'H.264/AAC',
                      ), // Replace with actual codec

                    if (options.showBitrate)
                      _buildCompactInfoRow(
                        'Bitrate',
                        '8.2 Mbps',
                      ), // Replace with actual bitrate

                    if (options.showDimensions)
                      _buildCompactInfoRow(
                        'Dimensions',
                        '1920 × 1080',
                      ), // Replace with actual dimensions
                    // Tags section
                    if (options.showTags) ...[
                      const SizedBox(height: 8),
                      TagSelector(filePath: item.path),
                    ],
                  ],
                ),
              ),

              // Remove Quick Actions section
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.mediaOptions;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio icon
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.audiotrack,
                    size: constraints.maxWidth * 0.3,
                    color: Colors.blue,
                  ),
                ),
              ),

              // Metadata section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Common info in compact layout
                    if (options.showSize)
                      _buildCompactInfoRow('Size', item.formattedSize),

                    if (options.showCreated)
                      _buildCompactInfoRow(
                        'Created',
                        item.formattedCreationTime,
                      ),

                    if (options.showModified)
                      _buildCompactInfoRow(
                        'Modified',
                        item.formattedModifiedTime,
                      ),

                    if (options.showWhereFrom && item.whereFrom != null)
                      _buildCompactInfoRow('Where from', item.whereFrom!),

                    const SizedBox(height: 8),

                    // Audio specific info
                    if (options.showDuration)
                      _buildCompactInfoRow(
                        'Duration',
                        '00:03:45',
                      ), // Replace with actual duration

                    if (options.showCodecs)
                      _buildCompactInfoRow(
                        'Codec',
                        'MP3',
                      ), // Replace with actual codec

                    if (options.showBitrate)
                      _buildCompactInfoRow(
                        'Bitrate',
                        '320 kbps',
                      ), // Replace with actual bitrate
                    // Tags section
                    if (options.showTags) ...[
                      const SizedBox(height: 8),
                      TagSelector(filePath: item.path),
                    ],
                  ],
                ),
              ),

              // Remove Quick Actions section
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.documentOptions;
    final ext = item.fileExtension.toLowerCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate icon size based on available width
        final iconSize = (constraints.maxWidth * 0.3).clamp(32.0, 64.0);

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
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(iconData, size: iconSize, color: iconColor),
                ),
              ),

              // Metadata section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Common info in compact layout
                    if (options.showSize)
                      _buildCompactInfoRow('Size', item.formattedSize),

                    if (options.showCreated)
                      _buildCompactInfoRow(
                        'Created',
                        item.formattedCreationTime,
                      ),

                    if (options.showModified)
                      _buildCompactInfoRow(
                        'Modified',
                        item.formattedModifiedTime,
                      ),

                    if (options.showWhereFrom && item.whereFrom != null)
                      _buildCompactInfoRow('Where from', item.whereFrom!),

                    // File type
                    _buildCompactInfoRow(
                      'Type',
                      '${item.fileExtension.toUpperCase().replaceAll('.', '')} File',
                    ),

                    // Tags section
                    if (options.showTags) ...[
                      const SizedBox(height: 8),
                      TagSelector(filePath: item.path),
                    ],
                  ],
                ),
              ),

              // Remove Quick Actions section
              const SizedBox(height: 16),
            ],
          ),
        );
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
                color: Colors.grey.shade600,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                // Common info
                if (options.showSize) _buildInfoRow('Size', item.formattedSize),

                if (options.showCreated)
                  _buildInfoRow('Created', item.formattedCreationTime),

                if (options.showModified)
                  _buildInfoRow('Modified', item.formattedModifiedTime),

                if (options.showWhereFrom && item.whereFrom != null)
                  _buildInfoRow('Where from', item.whereFrom!),

                // File type
                _buildInfoRow(
                  'Type',
                  '${item.fileExtension.toUpperCase().replaceAll('.', '')} File',
                ),

                // Tags section
                if (options.showTags) ...[
                  const SizedBox(height: 16),
                  TagSelector(filePath: item.path),
                ],
              ],
            ),
          ),

          // Remove Quick Actions section
          const SizedBox(height: 16),

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
              style: const TextStyle(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
