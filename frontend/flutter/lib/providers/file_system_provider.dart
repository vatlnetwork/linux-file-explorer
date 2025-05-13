import 'package:flutter/material.dart';
import 'dart:io';
import '../services/file_system_service.dart';
import '../services/folder_icon_service.dart';
import '../models/file_info.dart';

class FileSystemProvider extends ChangeNotifier {
  final FileSystemService _fileSystemService = FileSystemService();
  final FolderIconService _folderIconService = FolderIconService();
  String _currentPath = '/';
  List<FileInfo> _currentFiles = [];
  bool _isLoading = false;
  String? _error;

  String get currentPath => _currentPath;
  List<FileInfo> get currentFiles => _currentFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fileSystemService.init();
      await _folderIconService.init();
      await listDirectory(_currentPath);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> listDirectory(String path) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentPath = path;
      final entities = await _fileSystemService.listDirectory(path);
      _currentFiles = entities.map((entity) {
        final customIcon = entity is Directory ? _folderIconService.getFolderIcon(entity.path) : null;
        return FileInfo.fromFileSystemEntity(entity, customIcon: customIcon);
      }).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFolderIcon(String path, String iconPath) async {
    try {
      await _folderIconService.setFolderIcon(path, iconPath);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFolderIcon(String path) async {
    try {
      await _folderIconService.removeFolderIcon(path);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ... existing code ...
} 