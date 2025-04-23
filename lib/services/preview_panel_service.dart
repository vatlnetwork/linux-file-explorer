import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';
import '../widgets/get_info_dialog.dart';

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
  compressVideo
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
      actions.add(QuickAction.extractText);
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
        _handleConvertAudio(context);
        break;
    }
  }

  void _handleQuickLook(BuildContext context) {
    // TODO: Implement quick look functionality
  }

  void _handleOpen(BuildContext context) {
    // TODO: Implement open functionality
  }

  void _handleOpenWith(BuildContext context) {
    // TODO: Implement open with functionality
  }

  void _handleShare(BuildContext context) {
    // TODO: Implement share functionality
  }

  void _handleRename(BuildContext context) {
    // TODO: Implement rename functionality
  }

  void _handleCompress(BuildContext context) {
    // TODO: Implement compress functionality
  }

  void _handleDuplicate(BuildContext context) {
    // TODO: Implement duplicate functionality
  }

  void _handleRotate(BuildContext context) {
    // TODO: Implement rotate functionality
  }

  void _handleMarkup(BuildContext context) {
    // TODO: Implement markup functionality
  }

  void _handleCreatePdf(BuildContext context) {
    // TODO: Implement create PDF functionality
  }

  void _handleConvertImage(BuildContext context) {
    // TODO: Implement image conversion functionality
  }

  void _handleTrim(BuildContext context) {
    // TODO: Implement video trimming functionality
  }

  void _handleSearchablePdf(BuildContext context) {
    // TODO: Implement searchable PDF creation functionality
  }

  void _handleCopyPath(BuildContext context) {
    // TODO: Implement copy path functionality
  }

  void _handleCreateAlias(BuildContext context) {
    // TODO: Implement create alias functionality
  }

  void _handleAddToFavorites(BuildContext context) {
    // TODO: Implement add to favorites functionality
  }

  void _handleExtractText(BuildContext context) {
    // TODO: Implement extract text functionality
  }

  void _handleRevealInFolder(BuildContext context) {
    // TODO: Implement reveal in folder functionality
  }

  void _handleRunScript(BuildContext context) {
    // TODO: Implement run script functionality
  }

  void _handleConvertAudio(BuildContext context) {
    // TODO: Implement convert audio functionality
  }
} 