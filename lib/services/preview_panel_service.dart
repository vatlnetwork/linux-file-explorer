import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_item.dart';

class PreviewPanelService extends ChangeNotifier {
  static const String _showPreviewPanelKey = 'show_preview_panel';
  
  bool _showPreviewPanel = false;
  FileItem? _selectedItem;
  
  bool get showPreviewPanel => _showPreviewPanel;
  FileItem? get selectedItem => _selectedItem;
  
  PreviewPanelService() {
    _loadPreviewPanelState();
  }
  
  Future<void> _loadPreviewPanelState() async {
    final prefs = await SharedPreferences.getInstance();
    _showPreviewPanel = prefs.getBool(_showPreviewPanelKey) ?? false;
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
    }
    
    return false;
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
} 