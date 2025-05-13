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
import 'dart:developer' as developer;

enum QuickAction {
  rotate,
  markup,
  createPdf,
  searchablePdf,
  // New macOS Finder-like quick actions
  openWith,
  compress,
  duplicate,
  rename,
  quickLook,
  copyPath,
  getInfo,
  createAlias,
  addToFavorites,
  extractText,
  revealInFolder,
  convertAudio,
  compressVideo,
  extractFile,
  setWallpaper,
  extractAudio
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
        QuickAction.compress,
      ];
    }
    
    final ext = item.fileExtension.toLowerCase();
    final actions = <QuickAction>[];
    
    // Common actions for all files
    actions.add(QuickAction.openWith);
    actions.add(QuickAction.rename);
    actions.add(QuickAction.duplicate);
    actions.add(QuickAction.getInfo);
    actions.add(QuickAction.copyPath);
    actions.add(QuickAction.compress);
    
    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.rotate);
      actions.add(QuickAction.markup);
      actions.add(QuickAction.setWallpaper);
    }
    
    // Video files
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.compressVideo);
      actions.add(QuickAction.extractAudio);
    }
    
    // Audio files
    else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      actions.add(QuickAction.quickLook);
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
      actions.add(QuickAction.createPdf);
    }
    
    // Text files
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      actions.add(QuickAction.quickLook);
      actions.add(QuickAction.createPdf);
    }
    
    // Compressed files
    else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      actions.add(QuickAction.extractFile);
    }
    
    // Executable files
    else if (['.exe', '.sh', '.bat', '.bin', '.app'].contains(ext)) {
      // Executable files are not supported in the current QuickAction enum
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
      case QuickAction.searchablePdf:
        return 'Create Searchable PDF';
      // New quick actions
      case QuickAction.openWith:
        return 'Open With';
      case QuickAction.compress:
        return 'Compress';
      case QuickAction.duplicate:
        return 'Duplicate';
      case QuickAction.rename:
        return 'Rename';
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
      case QuickAction.convertAudio:
        return 'Convert Audio';
      case QuickAction.compressVideo:
        return 'Compress Video';
      case QuickAction.extractFile:
        return 'Extract File';
      case QuickAction.setWallpaper:
        return 'Set Wallpaper';
      case QuickAction.extractAudio:
        return 'Extract Audio';
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
      case QuickAction.searchablePdf:
        return Icons.search;
      // New quick action icons
      case QuickAction.openWith:
        return Icons.open_in_new;
      case QuickAction.compress:
        return Icons.archive;
      case QuickAction.duplicate:
        return Icons.file_copy;
      case QuickAction.rename:
        return Icons.drive_file_rename_outline;
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
      case QuickAction.convertAudio:
        return Icons.audiotrack;
      case QuickAction.compressVideo:
        return Icons.video_library;
      case QuickAction.extractFile:
        return Icons.file_download;
      case QuickAction.setWallpaper:
        return Icons.wallpaper;
      case QuickAction.extractAudio:
        return Icons.audiotrack;
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
      case QuickAction.openWith:
        _handleOpenWith(context);
        break;
      case QuickAction.getInfo:
        showDialog(
          context: context,
          builder: (context) => GetInfoDialog(item: _selectedItem!),
        );
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
        handleCompressVideo(context);
        break;
      case QuickAction.rotate:
        handleRotate(context);
        break;
      case QuickAction.markup:
        _handleMarkup(context);
        break;
      case QuickAction.createPdf:
        _handleCreatePdf(context);
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
      case QuickAction.convertAudio:
        handleConvertAudio(context);
        break;
      case QuickAction.extractFile:
        _handleExtractFile(context);
        break;
      case QuickAction.setWallpaper:
        _handleSetWallpaper(context);
        break;
      case QuickAction.extractAudio:
        _handleExtractAudio(context);
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
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Compressing ${_selectedItem!.type == FileItemType.directory ? 'Folder' : 'File'}...'),
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
      
      // Compress the file or folder
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
              Text('${_selectedItem!.type == FileItemType.directory ? 'Folder' : 'File'} compressed to ${p.basename(outputPath)}'),
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
          content: Text('Failed to compress ${_selectedItem!.type == FileItemType.directory ? 'folder' : 'file'}: $e'),
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

  void handleRotate(BuildContext context) async {
    if (_selectedItem == null) return;
    
    // Check if the file is an image
    final ext = _selectedItem!.fileExtension.toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rotation is only supported for image files')),
      );
      return;
    }
    
    try {
      // Check if ImageMagick is installed
      final result = await Process.run('which', ['convert']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ImageMagick is not installed. Please install it to use image rotation.'),
            action: SnackBarAction(
              label: 'Install',
              onPressed: () async {
                try {
                  await Process.run('sudo', ['dnf', 'install', '-y', 'ImageMagick']);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ImageMagick installed successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to install ImageMagick: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
        return;
      }
      
      // Show rotation options dialog
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
              ListTile(
                leading: const Icon(Icons.rotate_90_degrees_ccw),
                title: const Text('Rotate 180°'),
                onTap: () async {
                  Navigator.pop(context);
                  await _rotateImage(context, 180);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      developer.log('Error in handleRotate: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rotating image: $e')),
        );
      }
    }
  }
  
  Future<void> _rotateImage(BuildContext context, int degrees) async {
    if (_selectedItem == null) return;
    
    try {
      // Show loading dialog with progress
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Rotating image ${degrees > 0 ? 'right' : 'left'} ${degrees.abs()}°...'),
            ],
          ),
        ),
      );

      // Create a temporary file in the system temp directory
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/rotated_${_selectedItem!.name}');
      
      // Use ImageMagick to rotate the image
      final result = await Process.run('convert', [
        _selectedItem!.path,
        '-rotate',
        degrees.toString(),
        tempFile.path
      ]);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result.exitCode == 0) {
        // Create a backup of the original file
        final backupFile = File('${_selectedItem!.path}.bak');
        await File(_selectedItem!.path).copy(backupFile.path);
        
        try {
          // Replace the original file with the rotated one
          await tempFile.copy(_selectedItem!.path);
          
          // Delete the temporary files
          await tempFile.delete();
          await tempDir.delete(recursive: true);
          
          // Refresh the preview
          refreshSelectedItem();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image rotated ${degrees > 0 ? 'right' : 'left'} ${degrees.abs()}°'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    try {
                      await backupFile.copy(_selectedItem!.path);
                      await backupFile.delete();
                      refreshSelectedItem();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rotation undone')),
                        );
                      }
                    } catch (e) {
                      developer.log('Error undoing rotation: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to undo rotation: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }
        } catch (e) {
          // If something goes wrong, restore from backup
          await backupFile.copy(_selectedItem!.path);
          await backupFile.delete();
          rethrow;
        }
      } else {
        throw Exception('ImageMagick error: ${result.stderr}');
      }
    } catch (e) {
      developer.log('Error in _rotateImage: $e');
      // Close loading dialog if it's still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rotate image: $e')),
        );
      }
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

  void handleCompressVideo(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Check if FFmpeg is installed
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FFmpeg is not installed. Please install it to use video compression.'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      
      if (!context.mounted) return;
      
      // Show compression options dialog
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Compress Video'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('High Quality'),
                    subtitle: const Text('1080p, 8 Mbps'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _compressVideo(context, 'high');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Medium Quality'),
                    subtitle: const Text('720p, 4 Mbps'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _compressVideo(context, 'medium');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_library),
                    title: const Text('Low Quality'),
                    subtitle: const Text('480p, 2 Mbps'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _compressVideo(context, 'low');
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error compressing video: $e')),
        );
      }
    }
  }
  
  Future<void> _compressVideo(BuildContext context, String quality) async {
    if (_selectedItem == null) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Compressing Video...'),
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

      // Set compression parameters based on quality
      String resolution;
      String bitrate;
      switch (quality) {
        case 'high':
          resolution = '1920x1080';
          bitrate = '8M';
          break;
        case 'medium':
          resolution = '1280x720';
          bitrate = '4M';
          break;
        case 'low':
          resolution = '854x480';
          bitrate = '2M';
          break;
        default:
          resolution = '1280x720';
          bitrate = '4M';
      }

      // Create output file path
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}_compressed.mp4';
      
      // Compress video using FFmpeg
      final result = await Process.run('ffmpeg', [
        '-i', _selectedItem!.path,
        '-vf', 'scale=$resolution',
        '-b:v', bitrate,
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-c:a', 'aac',
        '-b:a', '128k',
        outputPath
      ]);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result.exitCode == 0) {
        // Get original and compressed sizes
        final originalSize = await File(_selectedItem!.path).length();
        final compressedSize = await File(outputPath).length();
        final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Video compressed to ${p.basename(outputPath)}'),
                  Text(
                    'Compression ratio: $ratio%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        // Refresh the preview
        refreshSelectedItem();
      } else {
        throw Exception(result.stderr);
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to compress video: $e')),
        );
      }
    }
  }

  void _handleSetWallpaper(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Show set wallpaper dialog
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Set Wallpaper'),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.wallpaper),
                    title: const Text('Set Wallpaper'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _setWallpaper(context);
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting wallpaper: $e')),
        );
      }
    }
  }
  
  Future<void> _setWallpaper(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Try different methods to set wallpaper based on desktop environment
      bool success = false;
      String errorMessage = '';

      // Method 1: Try using gsettings (GNOME)
      try {
        final result = await Process.run('gsettings', [
          'set',
          'org.gnome.desktop.background',
          'picture-uri',
          'file://${_selectedItem!.path}'
        ]);
        if (result.exitCode == 0) {
          success = true;
        } else {
          errorMessage = 'gsettings failed: ${result.stderr}';
        }
      } catch (e) {
        errorMessage = 'gsettings not available';
      }

      // Method 2: Try using feh
      if (!success) {
        try {
          final fehResult = await Process.run('which', ['feh']);
          if (fehResult.exitCode == 0) {
            final result = await Process.run('feh', ['--bg-scale', _selectedItem!.path]);
            if (result.exitCode == 0) {
              success = true;
            } else {
              errorMessage = 'feh failed: ${result.stderr}';
            }
          } else {
            errorMessage = 'feh not installed';
          }
        } catch (e) {
          errorMessage = 'feh command failed';
        }
      }

      // Method 3: Try using xfconf-query (XFCE)
      if (!success) {
        try {
          final result = await Process.run('xfconf-query', [
            '-c', 'xfce4-desktop',
            '-p', '/backdrop/screen0/monitor0/image-path',
            '-s', _selectedItem!.path
          ]);
          if (result.exitCode == 0) {
            success = true;
          } else {
            errorMessage = 'xfconf-query failed: ${result.stderr}';
          }
        } catch (e) {
          errorMessage = 'xfconf-query not available';
        }
      }
      
      // Method 4: Try using pcmanfm (LXDE)
      if (!success) {
        try {
          final result = await Process.run('pcmanfm', [
            '--set-wallpaper', _selectedItem!.path,
            '--wallpaper-mode=stretch'
          ]);
          if (result.exitCode == 0) {
            success = true;
          } else {
            errorMessage = 'pcmanfm failed: ${result.stderr}';
          }
        } catch (e) {
          errorMessage = 'pcmanfm not available';
        }
      }
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper set successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set wallpaper. $errorMessage\nPlease install a compatible wallpaper setter for your desktop environment.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wallpaper: $e')),
        );
      }
    }
  }

  void _handleExtractAudio(BuildContext context) async {
    if (_selectedItem == null) return;
    
    try {
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FFmpeg is not installed. Please install it to use audio extraction.')),
        );
        return;
      }
      
      final outputPath = '${_selectedItem!.path.substring(0, _selectedItem!.path.lastIndexOf('.'))}.wav';
      final extractResult = await Process.run('ffmpeg', [
        '-i', _selectedItem!.path,
        '-q:a', '0',
        '-map', 'a',
        outputPath
      ]);
      
      if (extractResult.exitCode == 0) {
        refreshSelectedItem();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio extracted to: ${p.basename(outputPath)}')),
        );
      } else {
        throw Exception(extractResult.stderr);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to extract audio: $e')),
      );
    }
  }
} 