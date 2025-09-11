// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/preview_panel_service.dart';
import '../services/bookmark_service.dart';
import '../states/file_explorer_state.dart';
import 'tag_selector.dart';

class PreviewPanel extends StatefulWidget {
  final Function(String) onNavigate;

  const PreviewPanel({super.key, required this.onNavigate});

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  Future<Map<String, dynamic>> getImageMetadata(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return {};
    }

    final image = await decodeImageFromList(await file.readAsBytes());
    final dimensions = {'width': image.width, 'height': image.height};

    // In a real app, you would extract more EXIF data here
    // For now, we'll just return dimensions
    return {
      'dimensions': '${dimensions['width']} × ${dimensions['height']}',
      'camera': 'Unknown',
      'exposure': 'N/A',
    };
  }

  String? _textContent;
  List<FileItem>? _directoryContent;
  bool _isLoading = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
    // Don't load preview in initState
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    return Consumer2<PreviewPanelService, FileExplorerState>(
      builder: (context, previewService, explorerState, _) {
        final selectedItem = previewService.selectedItem;
        final currentPath = explorerState.currentPath;
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(200.0, 400.0);
            final isPreviewing = selectedItem != null;
            final isImage =
                isPreviewing &&
                [
                  '.jpg',
                  '.jpeg',
                  '.png',
                  '.gif',
                  '.bmp',
                  '.webp',
                ].contains(selectedItem.fileExtension.toLowerCase());

            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(0),
              ),
              child: Stack(
                children: [
                  // Dynamic background based on preview content
                  if (isImage)
                    Container(
                      width: width,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(color: Colors.transparent),
                      ),
                    )
                  else
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: width,
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? Colors.black.withAlpha(40)
                                  : Colors.white.withAlpha(166),
                        ),
                      ),
                    ),

                  // Border and shadow
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color:
                              isDarkMode
                                  ? Colors.white.withAlpha(30)
                                  : Colors.grey.shade300.withAlpha(180),
                          width: 1.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isDarkMode
                                  ? Colors.black.withAlpha(80)
                                  : Colors.blueGrey.withAlpha(20),
                          blurRadius: 16,
                          offset: const Offset(-4, 0),
                        ),
                      ],
                    ),
                  ),

                  // Panel content
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selectedItem != null
                            ? _buildHeader(context, selectedItem)
                            : FutureBuilder<FileItem>(
                              future:
                                  (() async {
                                    final bookmarkService =
                                        Provider.of<BookmarkService>(
                                          context,
                                          listen: false,
                                        );
                                    final bookmarks = bookmarkService.bookmarks;
                                    final lastPath =
                                        bookmarkService
                                            .lastSelectedBookmarkPath;
                                    if (lastPath != null &&
                                        bookmarks.isNotEmpty) {
                                      final b = bookmarks.firstWhere(
                                        (b) => b.path == lastPath,
                                        orElse: () => bookmarks.first,
                                      );
                                      return FileItem.fromDirectory(
                                        Directory(b.path),
                                      );
                                    }
                                    if (bookmarks.isNotEmpty) {
                                      final b = bookmarks.first;
                                      return FileItem.fromDirectory(
                                        Directory(b.path),
                                      );
                                    }
                                    return FileItem(
                                      path: currentPath,
                                      name: p.basename(currentPath),
                                      type: FileItemType.directory,
                                      modifiedTime: DateTime.now(),
                                      creationTime: DateTime.now(),
                                      size: 0,
                                    );
                                  })(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox(height: 56);
                                }
                                return _buildHeader(context, snapshot.data!);
                              },
                            ),
                        if (isPreviewing)
                          SizedBox(
                            height:
                                constraints.maxHeight -
                                60, // leave space for header
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      _buildFileInfoPage(context, selectedItem),
                                      _buildDiskStatsPage(context),
                                      _buildTagsPage(context, selectedItem),
                                      _buildQuickActionsPage(
                                        context,
                                        selectedItem,
                                      ),
                                    ],
                                  ),
                                ),
                                _buildPageIndicator(4),
                              ],
                            ),
                          )
                        else
                          FutureBuilder<FileItem>(
                            future:
                                (() async {
                                  final bookmarkService =
                                      Provider.of<BookmarkService>(
                                        context,
                                        listen: false,
                                      );
                                  final bookmarks = bookmarkService.bookmarks;
                                  final lastPath =
                                      bookmarkService.lastSelectedBookmarkPath;
                                  if (lastPath != null &&
                                      bookmarks.isNotEmpty) {
                                    final b = bookmarks.firstWhere(
                                      (b) => b.path == lastPath,
                                      orElse: () => bookmarks.first,
                                    );
                                    return FileItem.fromDirectory(
                                      Directory(b.path),
                                    );
                                  }
                                  if (bookmarks.isNotEmpty) {
                                    final b = bookmarks.first;
                                    return FileItem.fromDirectory(
                                      Directory(b.path),
                                    );
                                  }
                                  return FileItem(
                                    path: currentPath,
                                    name: p.basename(currentPath),
                                    type: FileItemType.directory,
                                    modifiedTime: DateTime.now(),
                                    creationTime: DateTime.now(),
                                  );
                                })(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return _buildDirectoryPreview(
                                context,
                                snapshot.data!,
                              );
                            },
                          ),
                      ],
                    ),
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
    final iconColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

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
          IconButton(
            icon: Icon(Icons.close, size: 18, color: iconColor),
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

  Widget _buildFileInfoPage(BuildContext context, FileItem item) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final isDir = item.type == FileItemType.directory;
    final ext = item.fileExtension.toLowerCase();

    Widget content;
    if (isDir) {
      content = _buildFolderInfoPage(context, item);
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey(item.path + (_isLoading ? '_loading' : '')),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content],
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
          // Folder info section
          if (options.showFolderContents) ...[
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3C4043)
                        : const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Folder Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Text(
                'Folders (${folders.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 4.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
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
                              : const Color(0xFFF0F7FF),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Text(
                'Files (${files.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 4.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                final fileItem = files[index];
                return Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3C4043)
                            : const Color(0xFFF0F7FF),
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

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, FileItem item) {
    final previewService = Provider.of<PreviewPanelService>(context);
    final options = previewService.optionsManager.imageOptions;

    return FutureBuilder<Map<String, dynamic>>(
      future: getImageMetadata(item.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDefaultFileInfo(context, item);
        }

        final metadata = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = (constraints.maxWidth * 0.8).clamp(
              150.0,
              300.0,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: Container(
                        height: imageHeight,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.file(
                          File(item.path),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Could not load image'),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                        const SizedBox(height: 6),
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
                        if (options.showDimensions &&
                            metadata['dimensions'] != null)
                          _buildCompactInfoRow(
                            'Dimensions',
                            metadata['dimensions']!,
                          ),
                        if (options.showCameraModel &&
                            metadata['camera'] != null)
                          _buildCompactInfoRow('Camera', metadata['camera']!),
                        if (options.showExposureInfo &&
                            metadata['exposure'] != null)
                          _buildCompactInfoRow(
                            'Exposure',
                            metadata['exposure']!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTagsPage(BuildContext context, FileItem item) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TagSelector(filePath: item.path),
    );
  }

  Widget _buildQuickActionsPage(BuildContext context, FileItem item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    return Center(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildActionChip(
            icon: Icons.open_in_new,
            label: 'Open',
            color: iconColor,
            onTap: () => _openFile(item),
          ),
          _buildActionChip(
            icon: Icons.copy,
            label: 'Copy Path',
            color: iconColor,
            onTap: () => _copyPath(item),
          ),
          _buildActionChip(
            icon: Icons.folder_open,
            label: 'Reveal',
            color: iconColor,
            onTap: () => _revealInFolder(item),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed:
              _currentPage > 0
                  ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  : null,
        ),
        ...List.generate(pageCount, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.5),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed:
              _currentPage < pageCount - 1
                  ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                  : null,
        ),
      ],
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
          const SizedBox(width: 12),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
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
                child: Icon(
                  Icons.audiotrack,
                  size: constraints.maxWidth * 0.3,
                  color: Colors.blue,
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
                    // File type
                    _buildCompactInfoRow(
                      'Type',
                      '${item.fileExtension.toUpperCase().replaceAll('.', '')} File',
                    ),
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
                // File type
                _buildInfoRow(
                  'Type',
                  '${item.fileExtension.toUpperCase().replaceAll('.', '')} File',
                ),
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

// Moved into _PreviewPanelState
Widget _buildFolderInfoPage(BuildContext context, FileItem item) {
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

  return FutureBuilder<_FolderMetaData>(
    future: _getFolderMetaData(item.path),
    builder: (context, snapshot) {
      final meta = snapshot.data;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.folder,
                  size: 64,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Size', item.formattedSize),
                  _buildInfoRow('Created', item.formattedCreationTime),
                  _buildInfoRow('Modified', item.formattedModifiedTime),
                  if (meta != null) ...[
                    _buildInfoRow('Permissions', meta.permissions),
                    _buildInfoRow('Owner', meta.owner),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

class _FolderMetaData {
  final String permissions;
  final String owner;
  _FolderMetaData({required this.permissions, required this.owner});
}

Future<_FolderMetaData> _getFolderMetaData(String path) async {
  try {
    final result = await Process.run('stat', ['-c', '%A %U', path]);
    final parts = result.stdout.toString().trim().split(' ');
    if (parts.length >= 2) {
      return _FolderMetaData(permissions: parts[0], owner: parts[1]);
    }
  } catch (_) {}
  return _FolderMetaData(permissions: 'Unknown', owner: 'Unknown');
}

Widget _buildSimilarFilesList(BuildContext context, FileItem selectedItem) {
  final dir = Directory(
    selectedItem.type == FileItemType.directory
        ? selectedItem.path
        : p.dirname(selectedItem.path),
  );
  return FutureBuilder<List<FileItem>>(
    future: _getLargestFilesInDir(dir.path, exclude: selectedItem.path),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox.shrink();
      }
      final files = snapshot.data!;
      if (files.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Similar Files/Folders',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...files.map(
            (item) => ListTile(
              leading: Icon(
                item.type == FileItemType.directory
                    ? Icons.folder
                    : Icons.insert_drive_file,
                color:
                    item.type == FileItemType.directory
                        ? Colors.amber
                        : Colors.blueAccent,
              ),
              title: Text(item.name, overflow: TextOverflow.ellipsis),
              subtitle: Text(item.formattedSize),
              onTap: () {
                Provider.of<PreviewPanelService>(
                  context,
                  listen: false,
                ).setSelectedItem(item);
              },
            ),
          ),
        ],
      );
    },
  );
}

Future<List<FileItem>> _getLargestFilesInDir(
  String dirPath, {
  String? exclude,
}) async {
  try {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final entities = await dir.list().toList();
    final items = <FileItem>[];
    for (final entity in entities) {
      if (entity.path == exclude) continue;
      final stat = await entity.stat();
      if (entity is File) {
        items.add(
          FileItem(
            path: entity.path,
            name: p.basename(entity.path),
            type: FileItemType.file,
            modifiedTime: stat.modified,
            creationTime: stat.changed,
            size: stat.size,
          ),
        );
      } else if (entity is Directory) {
        items.add(
          FileItem(
            path: entity.path,
            name: p.basename(entity.path),
            type: FileItemType.directory,
            modifiedTime: stat.modified,
            creationTime: stat.changed,
            size: null,
          ),
        );
      }
    }
    items.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
    return items.take(5).toList();
  } catch (_) {
    return [];
  }
}

// Disk Stats Page (stub)
Widget _buildDiskStatsPage(BuildContext context) {
  final previewService = Provider.of<PreviewPanelService>(context);
  final selectedItem = previewService.selectedItem;
  if (selectedItem == null) {
    return const Center(child: Text('No item selected'));
  }
  return FutureBuilder<_DiskStatsData>(
    future: _getDiskStats(selectedItem),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final data = snapshot.data!;
      final percentItem = data.percentOfDisk;
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    percent: percentItem,
                    strokeWidth: 6,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(percentItem * 100).toStringAsFixed(percentItem < 0.01 ? 4 : 2)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'of Disk',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildDiskStatRow(
                'File/Folder Size',
                _formatBytes(data.itemSize),
              ),
              _buildDiskStatRow('Disk Total', _formatBytes(data.diskTotal)),
              _buildDiskStatRow(
                'Disk % Used',
                '${(percentItem * 100).toStringAsFixed(percentItem < 0.01 ? 4 : 2)}%',
              ),
              const SizedBox(height: 32),
              _buildSimilarFilesList(context, selectedItem),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDiskStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    ),
  );
}

class _DiskStatsData {
  final int itemSize;
  final int diskUsed;
  final int diskFree;
  final int diskTotal;
  final double percentOfDisk;
  _DiskStatsData({
    required this.itemSize,
    required this.diskUsed,
    required this.diskFree,
    required this.diskTotal,
    required this.percentOfDisk,
  });
}

Future<_DiskStatsData> _getDiskStats(FileItem item) async {
  final stat = await _getDiskSpace(item.path);
  final itemSize = await _getItemSize(item);
  final percent = stat.diskTotal > 0 ? itemSize / stat.diskTotal : 0.0;
  return _DiskStatsData(
    itemSize: itemSize,
    diskUsed: stat.diskUsed,
    diskFree: stat.diskFree,
    diskTotal: stat.diskTotal,
    percentOfDisk: percent,
  );
}

class _DiskSpaceInfo {
  final int diskUsed;
  final int diskFree;
  final int diskTotal;
  _DiskSpaceInfo({
    required this.diskUsed,
    required this.diskFree,
    required this.diskTotal,
  });
}

Future<_DiskSpaceInfo> _getDiskSpace(String path) async {
  try {
    final result = await Process.run('df', ['-B1', path]);
    final lines = result.stdout.toString().split('\n');
    if (lines.length >= 2) {
      final parts =
          lines[1].split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 5) {
        final total = int.tryParse(parts[1]) ?? 0;
        final used = int.tryParse(parts[2]) ?? 0;
        final free = int.tryParse(parts[3]) ?? 0;
        return _DiskSpaceInfo(diskUsed: used, diskFree: free, diskTotal: total);
      }
    }
  } catch (_) {}
  return _DiskSpaceInfo(diskUsed: 0, diskFree: 0, diskTotal: 0);
}

Future<int> _getItemSize(FileItem item) async {
  if (item.type == FileItemType.directory) {
    try {
      final result = await Process.run('du', ['-sb', item.path]);
      final sizeStr = result.stdout.toString().split(RegExp(r'\s+')).first;
      return int.tryParse(sizeStr) ?? 0;
    } catch (_) {
      return 0;
    }
  } else {
    final file = File(item.path);
    return await file.exists() ? await file.length() : 0;
  }
}

class _PieChartPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  _PieChartPainter({required this.percent, this.strokeWidth = 14});
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    final bgPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    final rect = Offset.zero & size;
    canvas.drawArc(rect, -1.57, 6.28, false, bgPaint);
    paint.color = Colors.blueAccent;
    canvas.drawArc(rect, -1.57, 6.28 * percent, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper to format bytes as human-readable string
String _formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
  final size = bytes / pow(1024, i);
  return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
}
