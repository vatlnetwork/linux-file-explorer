import 'dart:io';
import 'package:path/path.dart' as p;

/// Represents types of file system items
enum FileItemType {
  file,
  directory,
  symlink,
  unknown
}

/// Model class representing a file, folder or other file system item
class FileItem {
  /// Path to the file or directory
  final String path;
  
  /// Display name of the file or directory
  final String name;
  
  /// Type of the file system item
  final FileItemType type;
  
  /// Last modified time
  final DateTime? modifiedTime;
  
  /// Creation time
  final DateTime? creationTime;
  
  /// Where the file was downloaded from (for downloaded files)
  final String? whereFrom;
  
  /// File size in bytes (null for directories)
  final int? size;
  
  /// File extension (empty for directories)
  String get fileExtension {
    if (type != FileItemType.file) return '';
    
    final fileName = p.basename(path);
    final extension = p.extension(fileName);
    return extension;
  }
  
  /// Formatted size string
  String get formattedSize {
    if (size == null) return '';
    
    final kb = size! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
  
  /// Formatted modified time
  String get formattedModifiedTime {
    return modifiedTime?.toString() ?? 'Unknown';
  }
  
  /// Formatted creation time
  String get formattedCreationTime {
    return creationTime?.toString() ?? 'Unknown';
  }
  
  FileItem({
    required this.path,
    required this.name,
    required this.type,
    this.modifiedTime,
    this.creationTime,
    this.whereFrom,
    this.size,
  });
  
  /// Create a FileItem from a FileSystemEntity
  static Future<FileItem> fromEntity(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final name = entity.path.split('/').last;
    
    FileItemType type;
    if (entity is File) {
      type = FileItemType.file;
    } else if (entity is Directory) {
      type = FileItemType.directory;
    } else if (entity is Link) {
      type = FileItemType.symlink;
    } else {
      type = FileItemType.unknown;
    }
    
    return FileItem(
      path: entity.path,
      name: name,
      type: type,
      modifiedTime: stat.modified,
      creationTime: stat.changed, // Use changed as creation time
      size: entity is File ? stat.size : null,
    );
  }

  factory FileItem.fromFile(FileSystemEntity entity) {
    final File file = entity as File;
    final String name = p.basename(entity.path);
    final DateTime modifiedTime = file.statSync().modified;
    final DateTime creationTime = file.statSync().changed; // Use changed as creation time
    final int size = file.statSync().size;

    return FileItem(
      path: entity.path,
      name: name,
      type: FileItemType.file,
      modifiedTime: modifiedTime,
      creationTime: creationTime,
      size: size,
    );
  }

  factory FileItem.fromDirectory(FileSystemEntity entity) {
    final String name = p.basename(entity.path);
    final Directory dir = entity as Directory;
    final DateTime modifiedTime = dir.statSync().modified;
    final DateTime creationTime = dir.statSync().changed; // Use changed as creation time

    return FileItem(
      path: entity.path,
      name: name,
      type: FileItemType.directory,
      modifiedTime: modifiedTime,
      creationTime: creationTime,
    );
  }

  static FileItemType getType(FileSystemEntity entity) {
    if (entity is File) return FileItemType.file;
    if (entity is Directory) return FileItemType.directory;
    return FileItemType.unknown;
  }
} 