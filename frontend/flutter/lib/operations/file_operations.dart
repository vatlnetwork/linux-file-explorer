import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class FileOperations {
  Future<FileItem> createDirectory(String parentPath, String name) async {
    final path = p.join(parentPath, name);
    await Directory(path).create();
    return FileItem.fromEntity(Directory(path));
  }
  
  Future<FileItem> createFile(String parentPath, String name) async {
    final path = p.join(parentPath, name);
    await File(path).create();
    return FileItem.fromEntity(File(path));
  }
  
  Future<void> delete(String path) async {
    final entityType = FileSystemEntity.typeSync(path);
    if (entityType == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else {
      await File(path).delete();
    }
  }
  
  Future<FileItem> rename(String path, String newName) async {
    final parentPath = p.dirname(path);
    final newPath = p.join(parentPath, newName);
    
    final entity = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory
        ? Directory(path)
        : File(path);
    
    await entity.rename(newPath);
    return FileItem.fromEntity(entity);
  }
  
  Future<FileItem> copy(String sourcePath, String targetDir) async {
    final sourceName = p.basename(sourcePath);
    final targetPath = p.join(targetDir, sourceName);
    
    if (FileSystemEntity.typeSync(sourcePath) == FileSystemEntityType.directory) {
      await _copyDirectory(sourcePath, targetPath);
      return FileItem.fromEntity(Directory(targetPath));
    } else {
      await File(sourcePath).copy(targetPath);
      return FileItem.fromEntity(File(targetPath));
    }
  }
  
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    await Directory(targetPath).create();
    final sourceDir = Directory(sourcePath);
    await for (final entity in sourceDir.list(recursive: false)) {
      final name = p.basename(entity.path);
      final newPath = p.join(targetPath, name);
      await copy(entity.path, newPath);
    }
  }
  
  Future<String> getNonConflictingName(String targetPath) async {
    if (!await FileSystemEntity.isFile(targetPath) && 
        !await FileSystemEntity.isDirectory(targetPath)) {
      return targetPath;
    }
    
    final dirName = p.dirname(targetPath);
    final baseName = p.basenameWithoutExtension(targetPath);
    final extension = p.extension(targetPath);
    
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
} 