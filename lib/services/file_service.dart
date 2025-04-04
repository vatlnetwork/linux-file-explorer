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
} 