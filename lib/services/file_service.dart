import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import '../models/file_item.dart';

/// Service for handling file system operations
class FileService {
  final _logger = Logger('FileService');
  
  /// Get the home directory path
  Future<String> getHomeDirectory() async {
    return Platform.environment['HOME'] ?? '/';
  }
  
  /// List files and directories in a given path
  Future<List<FileItem>> listDirectory(String path) async {
    try {
      final directory = Directory(path);
      final entities = await directory.list().toList();
      final items = <FileItem>[];
      
      for (final entity in entities) {
        // Skip hidden files if needed
        final fileName = p.basename(entity.path);
        if (fileName.startsWith('.')) continue;
        
        try {
          final item = await FileItem.fromEntity(entity);
          items.add(item);
        } catch (e) {
          // Skip unreadable files
          _logger.warning('Error processing file ${entity.path}: $e');
        }
      }
      
      // Sort: directories first, then files
      items.sort((a, b) {
        if (a.type == FileItemType.directory && b.type != FileItemType.directory) {
          return -1;
        }
        if (a.type != FileItemType.directory && b.type == FileItemType.directory) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      return items;
    } catch (e) {
      throw Exception('Error listing directory: $e');
    }
  }
  
  /// Create a new directory
  Future<void> createDirectory(String parentPath, String name) async {
    final path = p.join(parentPath, name);
    await Directory(path).create();
  }
  
  /// Create a new file
  Future<void> createFile(String parentPath, String name) async {
    final path = p.join(parentPath, name);
    await File(path).create();
  }
  
  /// Rename a file or directory
  Future<void> rename(String path, String newName) async {
    final parentPath = p.dirname(path);
    final newPath = p.join(parentPath, newName);
    
    final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);
    
    await entity.rename(newPath);
  }
  
  /// Delete a file or directory
  Future<void> deleteFileOrDirectory(String path) async {
    final entityType = FileSystemEntity.typeSync(path);
    
    if (entityType == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }
  
  /// Copy a file or directory
  Future<void> copyFileOrDirectory(String sourcePath, String targetDir) async {
    final sourceName = p.basename(sourcePath);
    final targetPath = p.join(targetDir, sourceName);
    
    final entityType = FileSystemEntity.typeSync(sourcePath);
    
    if (entityType == FileSystemEntityType.directory) {
      // Create target directory
      final targetDir = Directory(targetPath);
      await targetDir.create();
      
      // Copy all contents
      final sourceDir = Directory(sourcePath);
      final contents = await sourceDir.list(recursive: false).toList();
      
      for (final entity in contents) {
        await copyFileOrDirectory(entity.path, targetPath);
      }
    } else {
      // Copy file
      final sourceFile = File(sourcePath);
      final targetFile = File(targetPath);
      await sourceFile.copy(targetFile.path);
    }
  }
  
  /// Move a file or directory
  Future<void> moveFileOrDirectory(String sourcePath, String targetDir) async {
    final sourceName = p.basename(sourcePath);
    final targetPath = p.join(targetDir, sourceName);
    
    final entity = FileSystemEntity.typeSync(sourcePath) == FileSystemEntityType.directory
        ? Directory(sourcePath)
        : File(sourcePath);
    
    await entity.rename(targetPath);
  }
} 