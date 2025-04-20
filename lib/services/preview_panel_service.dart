import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';

enum QuickAction {
  rotate,
  markup,
  createPdf,
  convertImage,
  trim,
  searchablePdf,
  share
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
      return [];
    }
    
    final ext = item.fileExtension.toLowerCase();
    final actions = <QuickAction>[];
    
    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      actions.add(QuickAction.rotate);
      actions.add(QuickAction.markup);
      actions.add(QuickAction.createPdf);
      actions.add(QuickAction.convertImage);
      actions.add(QuickAction.share);
    }
    
    // Video files
    else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      actions.add(QuickAction.trim);
      actions.add(QuickAction.share);
    }
    
    // PDF files - create searchable PDF option
    else if (['.pdf'].contains(ext)) {
      actions.add(QuickAction.searchablePdf);
      actions.add(QuickAction.markup);
      actions.add(QuickAction.share);
    }
    
    // Document files
    else if (['.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      actions.add(QuickAction.createPdf);
      actions.add(QuickAction.share);
    }
    
    // Text files
    else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      actions.add(QuickAction.markup);
      actions.add(QuickAction.createPdf);
      actions.add(QuickAction.share);
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
} 