import 'dart:io';
import 'package:path/path.dart' as p;
import 'folder_icon_service.dart';
import 'package:logging/logging.dart';

class FileSystemService {
  static final FileSystemService _instance = FileSystemService._internal();
  factory FileSystemService() => _instance;
  FileSystemService._internal();

  final FolderIconService _folderIconService = FolderIconService();
  final _logger = Logger('FileSystemService');

  Future<void> init() async {
    await _folderIconService.init();
  }

  Future<List<FileSystemEntity>> listDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw Exception('Directory does not exist');
    }

    final entities = await directory.list().toList();
    entities.sort((a, b) {
      // Sort directories first
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      // Then sort alphabetically
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    });

    return entities;
  }

  Future<Map<String, dynamic>> getFileInfo(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    final stat = await entity.stat();
    final isDirectory = entity is Directory;
    final customIcon = isDirectory ? _folderIconService.getFolderIcon(path) : null;

    return {
      'path': path,
      'name': p.basename(path),
      'size': stat.size,
      'modified': stat.modified,
      'isDirectory': isDirectory,
      'customIcon': customIcon,
    };
  }

  Future<String> getFileOwner(String path) async {
    try {
      final result = await Process.run('stat', ['-c', '%U', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      _logger.warning('Error getting file owner: $e');
    }
    return 'Unknown';
  }

  Future<String> getFileGroup(String path) async {
    try {
      final result = await Process.run('stat', ['-c', '%G', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      _logger.warning('Error getting file group: $e');
    }
    return 'Unknown';
  }
} 