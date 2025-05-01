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
  Future<List<FileItem>> listDirectory(String path, {bool showHidden = false}) async {
    try {
      final directory = Directory(path);
      final entities = await directory.list().toList();
      final items = <FileItem>[];
      
      for (final entity in entities) {
        // Skip hidden files if showHidden is false
        final fileName = p.basename(entity.path);
        if (!showHidden && fileName.startsWith('.')) continue;
        
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
  
  /// Generate a non-conflicting file name
  /// Returns a file name that doesn't exist in the target directory
  Future<String> getNonConflictingName(String targetPath) async {
    if (!await FileSystemEntity.isFile(targetPath) && 
        !await FileSystemEntity.isDirectory(targetPath)) {
      return targetPath; // No conflict
    }
    
    final dirName = p.dirname(targetPath);
    final baseName = p.basenameWithoutExtension(targetPath);
    final extension = p.extension(targetPath);
    
    // Try appending a counter
    int counter = 1;
    String newPath;
    
    do {
      String suffix = counter == 1 ? '_copy' : '_copy$counter';
      String newName = '$baseName$suffix$extension';
      newPath = p.join(dirName, newName);
      counter++;
    } while (await FileSystemEntity.isFile(newPath) || 
             await FileSystemEntity.isDirectory(newPath));
    
    return newPath;
  }
  
  /// Copy a file or directory
  /// If targetPath is null, the file will be copied to targetDir with the same name
  /// If handleConflicts is true, it will automatically rename files to avoid conflicts
  Future<String> copyFileOrDirectory(
    String sourcePath, 
    String targetDir, 
    {String? targetPath, bool handleConflicts = false}
  ) async {
    String finalTargetPath;
    
    if (targetPath != null) {
      // Use the provided full target path
      finalTargetPath = targetPath;
    } else {
      // Use the original behavior - create target path from source name
      final sourceName = p.basename(sourcePath);
      finalTargetPath = p.join(targetDir, sourceName);
    }
    
    // Handle conflicts if requested
    if (handleConflicts) {
      finalTargetPath = await getNonConflictingName(finalTargetPath);
    }
    
    final entityType = FileSystemEntity.typeSync(sourcePath);
    
    if (entityType == FileSystemEntityType.directory) {
      // Create target directory
      final targetDirObj = Directory(finalTargetPath);
      await targetDirObj.create();
      
      // Copy all contents
      final sourceDir = Directory(sourcePath);
      final contents = await sourceDir.list(recursive: false).toList();
      
      for (final entity in contents) {
        // For recursive copying, use the directory name
        await copyFileOrDirectory(entity.path, finalTargetPath);
      }
    } else {
      // Copy file
      final sourceFile = File(sourcePath);
      final targetFile = File(finalTargetPath);
      await sourceFile.copy(targetFile.path);
    }
    
    // Return the actual target path used (useful if conflict handling renamed the file)
    return finalTargetPath;
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
  
  /// Process multiple files asynchronously with progress reporting
  Future<void> processFilesAsync({
    required List<String> sourcePaths,
    required String targetDir,
    required bool isMove,
    required void Function(int progress, int total) onProgress,
  }) async {
    final total = sourcePaths.length;
    var completed = 0;

    // Process files in batches to avoid overwhelming the system
    const batchSize = 5;
    for (var i = 0; i < total; i += batchSize) {
      final batch = sourcePaths.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((sourcePath) async {
          try {
            if (isMove) {
              await moveFileOrDirectory(sourcePath, targetDir);
            } else {
              await copyFileOrDirectory(sourcePath, targetDir);
            }
          } catch (e) {
            _logger.warning('Error processing $sourcePath: $e');
            // Continue with other files even if one fails
          }
          completed++;
          onProgress(completed, total);
        }),
      );
    }
  }
  
  // Method to copy a file or folder from source to destination
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      // Get file info to determine if it's a directory
      final fileInfo = await File(sourcePath).stat();
      
      if (fileInfo.type == FileSystemEntityType.directory) {
        // Create the target directory
        await Directory(destinationPath).create(recursive: true);
        
        // Copy all contents
        final sourceDir = Directory(sourcePath);
        await for (final entity in sourceDir.list(recursive: false)) {
          final filename = p.basename(entity.path);
          final newDestPath = p.join(destinationPath, filename);
          
          await copyFile(entity.path, newDestPath);
        }
      } else {
        // Copy file
        await File(sourcePath).copy(destinationPath);
      }
      
      _logger.info('Copied $sourcePath to $destinationPath');
    } catch (e) {
      _logger.severe('Error copying file: $e');
      rethrow;
    }
  }
  
  // Method to move a file or folder from source to destination
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    try {
      // Get file info to determine if it's a directory
      final fileInfo = await File(sourcePath).stat();
      
      if (fileInfo.type == FileSystemEntityType.directory) {
        // Create the target directory
        await Directory(destinationPath).create(recursive: true);
        
        // Copy all contents
        final sourceDir = Directory(sourcePath);
        await for (final entity in sourceDir.list(recursive: false)) {
          final filename = p.basename(entity.path);
          final newDestPath = p.join(destinationPath, filename);
          
          await copyFile(entity.path, newDestPath);
        }
        
        // Delete the source directory
        await Directory(sourcePath).delete(recursive: true);
      } else {
        // Move file (rename operation in the file system)
        await File(sourcePath).rename(destinationPath);
      }
      
      _logger.info('Moved $sourcePath to $destinationPath');
    } catch (e) {
      _logger.severe('Error moving file: $e');
      rethrow;
    }
  }
  
  // Method to create a symbolic link
  Future<void> createSymlink(String targetPath, String linkPath) async {
    try {
      final link = Link(linkPath);
      await link.create(targetPath);
      _logger.info('Created symlink at $linkPath pointing to $targetPath');
    } catch (e) {
      _logger.severe('Error creating symlink: $e');
      rethrow;
    }
  }
} 