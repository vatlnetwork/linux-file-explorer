// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';
import '../services/preview_panel_service.dart';
import 'preview_options_dialog.dart';
import 'tag_selector.dart';
import 'dart:ui';

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

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(0),
              ),
              child: Stack(
                children: [
                  // Fluent glassy background
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width: width,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.black.withAlpha(40)
                                : Colors.white.withAlpha(166),
                        border: Border(
                          left: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.black.withAlpha(77)
                                    : Colors.grey.shade300.withAlpha(128),
                            width: 1.5,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                isDarkMode
                                    ? Colors.black.withAlpha(46)
                                    : Colors.blueGrey.withAlpha(20),
                            blurRadius: 16,
                            offset: const Offset(-4, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Panel content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, selectedItem),
                      if (selectedItem != null)
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildPreviewContent(context, selectedItem),
                          ),
                        )
                      else
                        Expanded(child: _buildNoSelectionView(context)),
                    ],
                  ),
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [
                    Color(0xFF23272E).withAlpha(217),
                    Color(0xFF23272E).withAlpha(166),
                  ]
                  : [Colors.white.withAlpha(217), Colors.white.withAlpha(166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color:
                isDarkMode
                    ? Colors.white.withAlpha(10)
                    : Colors.grey.shade200.withAlpha(128),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.blue.shade900.withAlpha(46)
                      : Colors.blue.shade100.withAlpha(179),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.preview,
              size: 20,
              color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selectedItem?.name ?? 'Preview',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (selectedItem != null) ...[
            IconButton(
              icon: const Icon(Icons.tune, size: 18),
              tooltip: 'Customize Preview',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
                maxWidth: 32,
                maxHeight: 32,
              ),
              onPressed: () => _showPreviewOptions(context, selectedItem),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
              maxWidth: 32,
              maxHeight: 32,
            ),
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
    final previewService = Provider.of<PreviewPanelService>(context);
    final isFile = item.type == FileItemType.file;
    final isDir = item.type == FileItemType.directory;
    final ext = item.fileExtension.toLowerCase();

    Widget content;
    if (isDir) {
      content = _buildDirectoryPreview(context, item);
    } else if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(ext)) {
      content = _buildImagePreview(context, item);
    } else if ([
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
      content = _buildTextPreview(context, item);
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      content = _buildVideoPreview(context, item);
    } else if ([
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
    ].contains(ext)) {
      content = _buildDocumentPreview(context, item);
    } else if (['.mp3', '.wav', '.flac'].contains(ext)) {
      content = _buildAudioPreview(context, item);
    } else {
      content = _buildDefaultFileInfo(context, item);
    }

    // Quick actions row for files
    Widget quickActions =
        isFile
            ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: 'Open',
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () => _openFile(item),
                    ),
                  ),
                  Tooltip(
                    message: 'Copy Path',
                    child: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () => _copyPath(item),
                    ),
                  ),
                  Tooltip(
                    message: 'Reveal in Folder',
                    child: IconButton(
                      icon: const Icon(Icons.folder_open, size: 20),
                      onPressed: () => _revealInFolder(item),
                    ),
                  ),
                ],
              ),
            )
            : const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey(item.path + (_isLoading ? '_loading' : '')),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content, quickActions],
      ),
    );
  }

  void _openFile(FileItem item) async {
    try {
      await Process.run('xdg-open', [item.path]);
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  void _copyPath(FileItem item) {
    Clipboard.setData(ClipboardData(text: item.path));
  }

  void _revealInFolder(FileItem item) async {
    final directory = Directory(item.path).parent.path;
    try {
      await Process.run('xdg-open', [directory]);
    } catch (e) {
      debugPrint('Error revealing folder: $e');
    }
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
                      minLeadingWidth: 24,
                      horizontalTitleGap: 8,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                    minLeadingWidth: 24,
                    horizontalTitleGap: 8,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
              width: double.infinity,
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade900
                              : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      previewText,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                      ),
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
                            Theme.of(context).brightness == Brightness.dark
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
                    _buildCompactInfoRow('Created', item.formattedCreationTime),

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
        );
      },
    );
  }

  Widget _buildVideoPreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final mediaOptions = previewService.optionsManager.mediaOptions;
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
                    if (mediaOptions.showSize)
                      _buildCompactInfoRow('Size', item.formattedSize),

                    if (mediaOptions.showCreated)
                      _buildCompactInfoRow(
                        'Created',
                        item.formattedCreationTime,
                      ),

                    if (mediaOptions.showModified)
                      _buildCompactInfoRow(
                        'Modified',
                        item.formattedModifiedTime,
                      ),

                    if (mediaOptions.showWhereFrom && item.whereFrom != null)
                      _buildCompactInfoRow('Where from', item.whereFrom!),

                    const SizedBox(height: 8),

                    // Media specific info
                    if (mediaOptions.showDuration)
                      _buildCompactInfoRow(
                        'Duration',
                        '00:01:24',
                      ), // Replace with actual duration

                    if (mediaOptions.showCodecs)
                      _buildCompactInfoRow(
                        'Codec',
                        'H.264/AAC',
                      ), // Replace with actual codec

                    if (mediaOptions.showBitrate)
                      _buildCompactInfoRow(
                        'Bitrate',
                        '8.2 Mbps',
                      ), // Replace with actual bitrate

                    if (mediaOptions.showDimensions)
                      _buildCompactInfoRow(
                        'Dimensions',
                        '1920 × 1080',
                      ), // Replace with actual dimensions
                    // Tags section
                    if (mediaOptions.showTags) ...[
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
