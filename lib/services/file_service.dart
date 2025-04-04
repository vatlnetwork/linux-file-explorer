import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class FileService {
  Future<String> getHomeDirectory() async {
    return '/home/${Platform.environment['USER'] ?? Platform.environment['LOGNAME']}';
  }

  Future<List<FileItem>> listDirectory(String path) async {
    final Directory directory = Directory(path);
    if (!directory.existsSync()) {
      throw Exception('Directory does not exist');
    }

    final List<FileSystemEntity> entities = directory.listSync();
    final List<FileItem> items = [];

    for (final entity in entities) {
      final FileItemType type = FileItem.getType(entity);
      
      if (type == FileItemType.file) {
        items.add(FileItem.fromFile(entity));
      } else if (type == FileItemType.directory) {
        items.add(FileItem.fromDirectory(entity));
      }
    }

    // Sort directories first, then files alphabetically
    items.sort((a, b) {
      if (a.type != b.type) {
        return a.type == FileItemType.directory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  Future<void> createDirectory(String parentPath, String name) async {
    final Directory newDir = Directory(p.join(parentPath, name));
    if (newDir.existsSync()) {
      throw Exception('Directory already exists');
    }

    await newDir.create();
  }

  Future<void> createFile(String parentPath, String name) async {
    final File newFile = File(p.join(parentPath, name));
    if (newFile.existsSync()) {
      throw Exception('File already exists');
    }

    await newFile.create();
  }

  Future<void> deleteFileOrDirectory(String path) async {
    final FileSystemEntity entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);

    if (!entity.existsSync()) {
      throw Exception('File or directory does not exist');
    }

    await entity.delete(recursive: true);
  }

  Future<void> rename(String path, String newName) async {
    final FileSystemEntity entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);

    if (!entity.existsSync()) {
      throw Exception('File or directory does not exist');
    }

    final String parentPath = p.dirname(path);
    final String newPath = p.join(parentPath, newName);

    await entity.rename(newPath);
  }

  Future<void> moveFileOrDirectory(String sourcePath, String destinationDir) async {
    final bool isDirectory = FileSystemEntity.typeSync(sourcePath) == FileSystemEntityType.directory;
    final String fileName = p.basename(sourcePath);
    final String destinationPath = p.join(destinationDir, fileName);
    
    // Check if source exists
    if (!(isDirectory ? Directory(sourcePath).existsSync() : File(sourcePath).existsSync())) {
      throw Exception('Source file or directory does not exist');
    }
    
    // Check if destination directory exists
    if (!Directory(destinationDir).existsSync()) {
      throw Exception('Destination directory does not exist');
    }
    
    // Use rename to move (works on same filesystem)
    try {
      final FileSystemEntity entity = isDirectory ? Directory(sourcePath) : File(sourcePath);
      await entity.rename(destinationPath);
    } catch (e) {
      // If rename fails (e.g., different filesystem), copy then delete
      await copyFileOrDirectory(sourcePath, destinationDir);
      await deleteFileOrDirectory(sourcePath);
    }
  }
  
  Future<void> copyFileOrDirectory(String sourcePath, String destinationDir) async {
    final bool isDirectory = FileSystemEntity.typeSync(sourcePath) == FileSystemEntityType.directory;
    final String fileName = p.basename(sourcePath);
    final String destinationPath = p.join(destinationDir, fileName);
    
    // Check if source exists
    if (!(isDirectory ? Directory(sourcePath).existsSync() : File(sourcePath).existsSync())) {
      throw Exception('Source file or directory does not exist');
    }
    
    // Check if destination directory exists
    if (!Directory(destinationDir).existsSync()) {
      throw Exception('Destination directory does not exist');
    }
    
    if (isDirectory) {
      // Create destination directory
      final Directory destinationDirectory = Directory(destinationPath);
      await destinationDirectory.create();
      
      // Copy all contents recursively
      final Directory sourceDirectory = Directory(sourcePath);
      await for (final FileSystemEntity entity in sourceDirectory.list(recursive: false)) {
        final String relativePath = p.relative(entity.path, from: sourcePath);
        final String targetPath = p.join(destinationPath, relativePath);
        
        if (entity is Directory) {
          await Directory(targetPath).create(recursive: true);
          await copyFileOrDirectory(entity.path, p.dirname(targetPath));
        } else if (entity is File) {
          await File(entity.path).copy(targetPath);
        }
      }
    } else {
      // For files, simply copy
      await File(sourcePath).copy(destinationPath);
    }
  }
} 