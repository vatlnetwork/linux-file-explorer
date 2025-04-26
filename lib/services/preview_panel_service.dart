// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';
import '../widgets/get_info_dialog.dart';
import '../widgets/rename_file_dialog.dart';
import '../services/quick_look_service.dart';
import 'package:path/path.dart' as p;
import '../widgets/markup_editor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/services.dart';
import '../services/compression_service.dart';

enum QuickAction {
  rotate,
  markup,
  createPdf,
  convertImage,
  trim,
  searchablePdf,
  share,
  // New macOS Finder-like quick actions
  openWith,
  compress,
  duplicate,
  rename,
  preview,
  quickLook,
  copyPath,
  getInfo,
  createAlias,
  addToFavorites,
  extractText,
  revealInFolder,
  runScript,
  convertAudio,
  compressVideo,
  extractFile
}

class PreviewPanelService extends ChangeNotifier {
  static const String _showPreviewPanelKey = 'show_preview_panel';
  
  bool _showPreviewPanel = false;
  FileItem? _selectedItem;
  final PreviewOptionsManager _optionsManager = PreviewOptionsManager();
  
  bool get showPreviewPanel => _showPreviewPanel;
  FileItem? get selectedItem => _selectedItem;
  PreviewOptionsManager get optionsManager => _optionsManager;
  
  PreviewPanelService() {
    _loadPreviewPanelState();
  }
  
  Future<void> _loadPreviewPanelState() async {
    final prefs = await SharedPreferences.getInstance();
    _showPreviewPanel = prefs.getBool(_showPreviewPanelKey) ?? false;
    await _optionsManager.loadOptions();
    notifyListeners();
  }
  
  Future<void> togglePreviewPanel() async {
    _showPreviewPanel = !_showPreviewPanel;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPreviewPanelKey, _showPreviewPanel);
  }
  
  void setSelectedItem(FileItem? item) {
    _selectedItem = item;
    notifyListeners();
  }
  
  /// Refresh the current selected item to reflect file system changes
  Future<void> refreshSelectedItem() async {
    if (_selectedItem == null) return;
    
    try {
      final path = _selectedItem!.path;
      final entity = FileSystemEntity.isDirectorySync(path) 
          ? Directory(path) as FileSystemEntity
          : File(path);
      
      if (await entity.exists()) {
        // Create a new FileItem with updated information
        final refreshedItem = await FileItem.fromEntity(entity);
        setSelectedItem(refreshedItem);
      } else {
        // If the file no longer exists, clear the selection
        setSelectedItem(null);
      }
    } catch (e) {
      debugPrint('Error refreshing selected item: $e');
    }
    
    notifyListeners();
  }
  
  bool canPreview(FileItem? item) {
    if (item == null) return false;
    
    if (item.type == FileItemType.directory) {
      return true; // We can preview directories by showing content list
    }
    
    if (item.type == FileItemType.file) {
      final ext = item.fileExtension.toLowerCase();
      
      // Image files
      if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
        return true;
      }
      
      // Text files
      if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
        return true;
      }
      
      // Document preview might be limited but we can show some info
      if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
        return true;
      }
      
      // Video preview (thumbnail)
      if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
        return true;
      }
      
      // Audio files
      if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get available quick actions for a file type
  List<QuickAction> getQuickActionsFor(FileItem item) {
    if (item.type != FileItemType.file) {
      return [
        QuickAction.getInfo,
        QuickAction.addToFavorites,
        QuickAction.revealInFolder,
        QuickAction.rename,
        QuickAction.duplicate,
      ];
    }
    
    final ext = item.fileExtension.toLowerCase();
    final actions = <QuickAction>[];
    
    // Common actions for all files
    actions.add(QuickAction.openWith);
    actions.add(QuickAction.rename);
    actions.add(QuickAction.duplicate);
    actions.add(QuickAction.share);
    actions.add(QuickAction.getInfo);
    actions.add(QuickAction.copyPath);
    actions.add(QuickAction.compress);
    
    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.rotate);
      actions.add(QuickAction.markup);
      actions.add(QuickAction.convertImage);
    }
    
    // Video files
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.preview);
      actions.add(QuickAction.trim);
      actions.add(QuickAction.compressVideo);
    }
    
    // Audio files
    else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.preview);
      actions.add(QuickAction.convertAudio);
    }
    
    // PDF files
    else if (['.pdf'].contains(ext)) {
      actions.add(QuickAction.searchablePdf);
      actions.add(QuickAction.extractText);
    }
    
    // Document files
    else if (['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.preview);
      actions.add(QuickAction.createPdf);
      actions.add(QuickAction.extractText);
    }
    
    // Text files
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.createPdf);
      actions.add(QuickAction.runScript);
    }
    
    // Compressed files
    else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      actions.add(QuickAction.extractFile);
    }
    
    // Executable files
    else if (['.exe', '.sh', '.bat', '.bin', '.app'].contains(ext)) {
      actions.add(QuickAction.runScript);
    }
    
    return actions;
  }
  
  String getQuickActionName(QuickAction action) {
    switch (action) {
      case QuickAction.rotate:
        return 'Rotate';
      case QuickAction.markup:
        return 'Markup';
      case QuickAction.createPdf:
        return 'Create PDF';
      case QuickAction.convertImage:
        return 'Convert Image';
      case QuickAction.trim:
        return 'Trim';
      case QuickAction.searchablePdf:
        return 'Create Searchable PDF';
      case QuickAction.share:
        return 'Share';
      // New quick actions
      case QuickAction.openWith:
        return 'Open With';
      case QuickAction.compress:
        return 'Compress';
      case QuickAction.duplicate:
        return 'Duplicate';
      case QuickAction.rename:
        return 'Rename';
      case QuickAction.preview:
        return 'Preview';
      case QuickAction.quickLook:
        return 'Quick Look';
      case QuickAction.copyPath:
        return 'Copy Path';
      case QuickAction.getInfo:
        return 'Get Info';
      case QuickAction.createAlias:
        return 'Create Alias';
      case QuickAction.addToFavorites:
        return 'Add to Favorites';
      case QuickAction.extractText:
        return 'Extract Text';
      case QuickAction.revealInFolder:
        return 'Reveal in Folder';
      case QuickAction.runScript:
        return 'Run Script';
      case QuickAction.convertAudio:
        return 'Convert Audio';
      case QuickAction.compressVideo:
        return 'Compress Video';
      case QuickAction.extractFile:
        return 'Extract File';
    }
  }
  
  IconData getQuickActionIcon(QuickAction action) {
    switch (action) {
      case QuickAction.rotate:
        return Icons.rotate_right;
      case QuickAction.markup:
        return Icons.edit;
      case QuickAction.createPdf:
        return Icons.picture_as_pdf;
      case QuickAction.convertImage:
        return Icons.transform;
      case QuickAction.trim:
        return Icons.content_cut;
      case QuickAction.searchablePdf:
        return Icons.search;
      case QuickAction.share:
        return Icons.share;
      // New quick action icons
      case QuickAction.openWith:
        return Icons.open_in_new;
      case QuickAction.compress:
        return Icons.archive;
      case QuickAction.duplicate:
        return Icons.file_copy;
      case QuickAction.rename:
        return Icons.drive_file_rename_outline;
      case QuickAction.preview:
        return Icons.preview;
      case QuickAction.quickLook:
        return Icons.visibility;
      case QuickAction.copyPath:
        return Icons.link;
      case QuickAction.getInfo:
        return Icons.info_outline;
      case QuickAction.createAlias:
        return Icons.shortcut;
      case QuickAction.addToFavorites:
        return Icons.star_border;
      case QuickAction.extractText:
        return Icons.text_snippet;
      case QuickAction.revealInFolder:
        return Icons.folder_open;
      case QuickAction.runScript:
        return Icons.terminal;
      case QuickAction.convertAudio:
        return Icons.audiotrack;
      case QuickAction.compressVideo:
        return Icons.video_library;
      case QuickAction.extractFile:
        return Icons.file_download;
    }
  }
  
  Future<String?> getTextFileContent(String path, {int maxLines = 200}) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      
      final size = file.lengthSync();
      if (size > 1024 * 1024) { // Don't try to read files larger than 1MB
        return "File too large to preview";
      }
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      if (lines.length > maxLines) {
        return '${lines.take(maxLines).join('\n')}\n\n[File truncated, too many lines to display]';
      }
      
      return content;
    } catch (e) {
      return "Unable to read file: $e";
    }
  }
  
  Future<List<FileItem>> getDirectoryContent(String path, {int maxItems = 100}) async {
    try {
      final directory = Directory(path);
      if (!directory.existsSync()) return [];
      
      final entities = directory.listSync(followLinks: false);
      final items = <FileItem>[];
      
      for (final entity in entities.take(maxItems)) {
        final type = FileItem.getType(entity);
        if (type == FileItemType.file) {
          items.add(FileItem.fromFile(entity));
        } else if (type == FileItemType.directory) {
          items.add(FileItem.fromDirectory(entity));
        }
      }
      
      // Sort directories first, then files
      items.sort((a, b) {
        if (a.type != b.type) {
          return a.type == FileItemType.directory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      return items;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> savePreviewOptions(PreviewOptions options, String fileExtension) async {
    final ext = fileExtension.toLowerCase();
    
    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      await _optionsManager.saveImageOptions(options);
    }
    
    // Document files
    else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      await _optionsManager.saveDocumentOptions(options);
    }
    
    // Media files
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm', '.mp3', '.wav', '.aac', '.flac'].contains(ext)) {
      await _optionsManager.saveMediaOptions(options);
    }
    
    // Default
    else {
      await _optionsManager.saveDefaultOptions(options);
    }
    
    notifyListeners();
  }

  void handleQuickAction(QuickAction action, BuildContext context) {
    switch (action) {
      case QuickAction.quickLook:
        _handleQuickLook(context);
        break;
      case QuickAction.preview:
        _handleOpen(context);
        break;
      case QuickAction.openWith:
        _handleOpenWith(context);
        break;
      case QuickAction.getInfo:
        showDialog(
          context: context,
          builder: (context) => GetInfoDialog(item: _selectedItem!),
        );
        break;
      case QuickAction.share:
        _handleShare(context);
        break;
      case QuickAction.rename:
        _handleRename(context);
        break;
      case QuickAction.compress:
        _handleCompress(context);
        break;
      case QuickAction.duplicate:
        _handleDuplicate(context);
        break;
      case QuickAction.compressVideo:
        _handleCompress(context);
        break;
      case QuickAction.rotate:
        _handleRotate(context);
        break;
      case QuickAction.markup:
        _handleMarkup(context);
        break;
      case QuickAction.createPdf:
        _handleCreatePdf(context);
        break;
      case QuickAction.convertImage:
        _handleConvertImage(context);
        break;
      case QuickAction.trim:
        _handleTrim(context);
        break;
      case QuickAction.searchablePdf:
        _handleSearchablePdf(context);
        break;
      case QuickAction.copyPath:
        _handleCopyPath(context);
        break;
      case QuickAction.createAlias:
        _handleCreateAlias(context);
        break;
      case QuickAction.addToFavorites:
        _handleAddToFavorites(context);
        break;
      case QuickAction.extractText:
        _handleExtractText(context);
        break;
      case QuickAction.revealInFolder:
        _handleRevealInFolder(context);
        break;
      case QuickAction.runScript:
        _handleRunScript(context);
        break;
      case QuickAction.convertAudio:
        handleConvertAudio(context);
        break;
      case QuickAction.extractFile:
        _handleExtractFile(context);
        break;
    }
  }

  void _handleQuickLook(BuildContext context) {
    if (_selectedItem == null) return;
    
    final quickLookService = QuickLookService(
      context: context,
      previewPanelService: this,
    );
    quickLookService.showQuickLook(_selectedItem!);
  }

  void _handleOpen(BuildContext context) {
    if (_selectedItem == null) return;
    
    try {
      final process = Process.run('xdg-open', [_selectedItem!.path]);
      process.then((result) {
        if (result.exitCode != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open file: ${result.stderr}')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening file: $e')),
      );
    }
  }

  void _handleOpenWith(BuildContext context) {
    if (_selectedItem == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open With'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Text Editor'),
                onTap: () {
                  Navigator.pop(context);
                  Process.run('xdg-open', ['-a', 'gedit', _selectedItem!.path]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Image Viewer'),
                onTap: () {
                  Navigator.pop(context);
                  Process.run('xdg-open', ['-a', 'eog', _selectedItem!.path]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video Player'),
                onTap: () {
                  Navigator.pop(context);
                  Process.run('xdg-open', ['-a', 'vlc', _selectedItem!.path]);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context) {
    if (_selectedItem == null) return;
    
    try {
      final process = Process.run('xdg-open', ['--share', _selectedItem!.path]);
      process.then((result) {
        if (result.exitCode != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to share file: ${result.stderr}')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }

  void _handleRename(BuildContext context) {
    if (_selectedItem == null) return;
    
    showDialog(
      context: context,
      builder: (context) => RenameFileDialog(fileItem: _selectedItem!),
    ).then((success) {
      if (success == true) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File renamed successfully')),
        );
      }
    });
  }

  void _handleCompress(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Show loading dialog with progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Compressing...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Compressing ${_selectedItem!.name}...'),
            ],
          ),
        ),
      );

      // Get the compression service
      final compressionService = CompressionService();
      
      // Get original size for comparison
      final originalSize = await compressionService.getUncompressedSize(_selectedItem!.path);
      
      // Compress the file
      final outputPath = await compressionService.compressToZip(_selectedItem!.path);
      
      // Get compressed size
      final compressedSize = await compressionService.getCompressedSize(outputPath);
      
      // Calculate compression ratio
      final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message with compression details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File compressed to ${p.basename(outputPath)}'),
              Text(
                'Compression ratio: $ratio%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Refresh the directory view
      refreshSelectedItem();
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to compress file: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleDuplicate(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final parentDir = p.dirname(_selectedItem!.path);
      final fileName = p.basename(_selectedItem!.path);
      final baseName = p.basenameWithoutExtension(fileName);
      final extension = p.extension(fileName);
      
      String newPath = p.join(parentDir, '${baseName}_copy$extension');
      int counter = 1;
      
      while (await File(newPath).exists()) {
        newPath = p.join(parentDir, '${baseName}_copy($counter)$extension');
        counter++;
      }
      
      await File(_selectedItem!.path).copy(newPath);
      refreshSelectedItem();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File duplicated: ${p.basename(newPath)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to duplicate file: $e')),
      );
    }
  }

  void _handleRotate(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['convert']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ImageMagick is not installed. Please install it to use image rotation.')),
        );
        return;
      }
      
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rotate Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.rotate_right),
                title: const Text('Rotate 90° Right'),
                onTap: () async {
                  Navigator.pop(context);
                  await _rotateImage(context, 90);
                },
              ),
              ListTile(
                leading: const Icon(Icons.rotate_left),
                title: const Text('Rotate 90° Left'),
                onTap: () async {
                  Navigator.pop(context);
                  await _rotateImage(context, -90);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rotating image: $e')),
      );
    }
  }
  
  Future<void> _rotateImage(BuildContext context, int degrees) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('convert', [
        _selectedItem!.path,
        '-rotate',
        degrees.toString(),
        _selectedItem!.path
      ]);
      
      if (result.exitCode == 0) {
        refreshSelectedItem();
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rotate image: $e')),
      );
    }
  }

  void _handleMarkup(BuildContext context) {
    if (_selectedItem == null) return;
    
    final ext = _selectedItem!.fileExtension.toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Markup editor only supports image files')),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkupEditor(fileItem: _selectedItem!),
      ),
    ).then((success) {
      if (success == true) {
        refreshSelectedItem();
      }
    });
  }

  void _handleCreatePdf(BuildContext context) async {
    if (_selectedItem == null) return;
    
    final ext = _selectedItem!.fileExtension.toLowerCase();
    if (!['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF creation is currently only supported for text files')),
      );
      return;
    }
    
    try {
      final content = await File(_selectedItem!.path).readAsString();
      final document = PdfDocument();
      final page = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final brush = PdfSolidBrush(PdfColor(0, 0, 0));
      final format = PdfStringFormat(wordWrap: PdfWordWrapType.word, lineSpacing: 20);
      
      page.graphics.drawString(
        content,
        font,
        brush: brush,
        format: format,
        bounds: Rect.fromLTWH(50, 50, page.getClientSize().width - 100, page.getClientSize().height - 100),
      );
      
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}.pdf';
      final bytes = await document.save();
      await File(outputPath).writeAsBytes(bytes);
      document.dispose();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF created successfully at $outputPath')),
      );
      refreshSelectedItem();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating PDF: $e')),
      );
    }
  }

  void _handleConvertImage(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['convert']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ImageMagick is not installed. Please install it to use image conversion.')),
        );
        return;
      }
      
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Convert Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('PNG'),
                onTap: () async {
                  Navigator.pop(context);
                  await _convertImageTo(context, 'png');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('JPEG'),
                onTap: () async {
                  Navigator.pop(context);
                  await _convertImageTo(context, 'jpeg');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('WebP'),
                onTap: () async {
                  Navigator.pop(context);
                  await _convertImageTo(context, 'webp');
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error converting image: $e')),
      );
    }
  }
  
  Future<void> _convertImageTo(BuildContext context, String format) async {
    if (_selectedItem == null) return;
    
    try {
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}.$format';
      final result = await Process.run('convert', [
        _selectedItem!.path,
        outputPath
      ]);
      
      if (result.exitCode == 0) {
        refreshSelectedItem();
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to convert image: $e')),
      );
    }
  }

  void _handleTrim(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FFmpeg is not installed. Please install it to use video trimming.')),
        );
        return;
      }
      
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Trim Video'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.content_cut),
                title: const Text('Trim Start'),
                onTap: () async {
                  Navigator.pop(context);
                  await _trimVideo(context, 'start');
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_cut),
                title: const Text('Trim End'),
                onTap: () async {
                  Navigator.pop(context);
                  await _trimVideo(context, 'end');
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error trimming video: $e')),
      );
    }
  }
  
  Future<void> _trimVideo(BuildContext context, String position) async {
    if (_selectedItem == null) return;
    
    try {
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}_trimmed.mp4';
      final result = await Process.run('ffmpeg', [
        '-i', _selectedItem!.path,
        '-ss', position == 'start' ? '00:00:05' : '00:00:00',
        '-t', position == 'start' ? '00:00:00' : '00:00:05',
        '-c', 'copy',
        outputPath
      ]);
      
      if (result.exitCode == 0) {
        refreshSelectedItem();
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trim video: $e')),
      );
    }
  }

  void _handleSearchablePdf(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Check for required tools
      final ffmpegResult = await Process.run('which', ['ffmpeg']);
      final tesseractResult = await Process.run('which', ['tesseract']);
      
      if (ffmpegResult.exitCode != 0 || tesseractResult.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FFmpeg and Tesseract OCR are required for searchable PDF creation.')),
        );
        return;
      }
      
      // Convert PDF pages to images
      final tempDir = Directory.systemTemp.createTempSync();
      final result = await Process.run('ffmpeg', [
        '-i', _selectedItem!.path,
        '-r', '1',
        '-f', 'image2',
        '${tempDir.path}/page_%d.png'
      ]);
      
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
      
      // OCR each page and create searchable PDF
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}_searchable.pdf';
      final ocrResult = await Process.run('tesseract', [
        '${tempDir.path}/page_*.png',
        outputPath,
        'pdf'
      ]);
      
      if (ocrResult.exitCode == 0) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Searchable PDF created: ${p.basename(outputPath)}')),
        );
      } else {
        throw Exception(ocrResult.stderr);
      }
      
      // Clean up temp files
      tempDir.deleteSync(recursive: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create searchable PDF: $e')),
      );
    }
  }

  void _handleCopyPath(BuildContext context) {
    if (_selectedItem == null) return;
    
    Clipboard.setData(ClipboardData(text: _selectedItem!.path)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path copied to clipboard')),
      );
    });
  }

  void _handleCreateAlias(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final parentDir = p.dirname(_selectedItem!.path);
      final fileName = p.basename(_selectedItem!.path);
      final aliasPath = p.join(parentDir, '${fileName}_alias');
      
      final result = await Process.run('ln', ['-s', _selectedItem!.path, aliasPath]);
      
      if (result.exitCode == 0) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alias created: ${p.basename(aliasPath)}')),
        );
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create alias: $e')),
      );
    }
  }

  void _handleAddToFavorites(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final favoritesDir = Directory('${Platform.environment['HOME']}/.favorites');
      if (!await favoritesDir.exists()) {
        await favoritesDir.create();
      }
      
      final aliasPath = p.join(favoritesDir.path, p.basename(_selectedItem!.path));
      final result = await Process.run('ln', ['-s', _selectedItem!.path, aliasPath]);
      
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added to favorites: ${p.basename(aliasPath)}')),
        );
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to favorites: $e')),
      );
    }
  }

  void _handleExtractText(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['tesseract']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tesseract OCR is not installed. Please install it to use text extraction.')),
        );
        return;
      }
      
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}.txt';
      final ocrResult = await Process.run('tesseract', [
        _selectedItem!.path,
        outputPath.substring(0, outputPath.lastIndexOf('.')),
        '-l', 'eng'
      ]);
      
      if (ocrResult.exitCode == 0) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Text extracted to: ${p.basename(outputPath)}')),
        );
      } else {
        throw Exception(ocrResult.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract text: $e')),
      );
    }
  }

  void _handleRevealInFolder(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final parentDir = p.dirname(_selectedItem!.path);
      final result = await Process.run('xdg-open', [parentDir]);
      
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reveal in folder: $e')),
      );
    }
  }

  void _handleRunScript(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Make the file executable
      await Process.run('chmod', ['+x', _selectedItem!.path]);
      
      // Run the script
      final result = await Process.run(_selectedItem!.path, []);
      
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Script executed successfully: ${result.stdout}')),
        );
      } else {
        throw Exception('${result.stderr}\nExit code: ${result.exitCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to run script: $e')),
      );
    }
  }

  void handleConvertAudio(BuildContext context) async {
    if (_selectedItem == null) return;
    
    // Check if ffmpeg is installed
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ffmpeg is not installed. Please install it to use audio conversion features.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error checking for ffmpeg installation.'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    
    if (!context.mounted) return;
    
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Convert Audio'),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('MP3'),
                  subtitle: const Text('High quality audio'),
                  onTap: () async {
                    Navigator.pop(context);
                    final outputPath = '${_selectedItem!.path}.mp3';
                    try {
                      final result = await Process.run('ffmpeg', [
                        '-i', _selectedItem!.path,
                        '-codec:a', 'libmp3lame',
                        '-qscale:a', '2',
                        outputPath
                      ]);
                      if (result.exitCode == 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio converted to MP3 successfully')),
                          );
                        }
                      } else {
                        throw Exception(result.stderr);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to convert audio: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('WAV'),
                  subtitle: const Text('Lossless audio'),
                  onTap: () async {
                    Navigator.pop(context);
                    final outputPath = '${_selectedItem!.path}.wav';
                    try {
                      final result = await Process.run('ffmpeg', [
                        '-i', _selectedItem!.path,
                        '-codec:a', 'pcm_s16le',
                        outputPath
                      ]);
                      if (result.exitCode == 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio converted to WAV successfully')),
                          );
                        }
                      } else {
                        throw Exception(result.stderr);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to convert audio: $e')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('FLAC'),
                  subtitle: const Text('Lossless compressed'),
                  onTap: () async {
                    Navigator.pop(context);
                    final outputPath = '${_selectedItem!.path}.flac';
                    try {
                      final result = await Process.run('ffmpeg', [
                        '-i', _selectedItem!.path,
                        '-codec:a', 'flac',
                        outputPath
                      ]);
                      if (result.exitCode == 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio converted to FLAC successfully')),
                          );
                        }
                      } else {
                        throw Exception(result.stderr);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to convert audio: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleExtractFile(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['tesseract']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tesseract OCR is not installed. Please install it to use text extraction.')),
        );
        return;
      }
      
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}.txt';
      final ocrResult = await Process.run('tesseract', [
        _selectedItem!.path,
        outputPath.substring(0, outputPath.lastIndexOf('.')),
        '-l', 'eng'
      ]);
      
      if (ocrResult.exitCode == 0) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Text extracted to: ${p.basename(outputPath)}')),
        );
      } else {
        throw Exception(ocrResult.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract text: $e')),
      );
    }
  }
} 