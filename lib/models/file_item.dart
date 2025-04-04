import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

enum FileItemType {
  file,
  directory,
  unknown,
}

class FileItem {
  final String path;
  final String name;
  final FileItemType type;
  final DateTime? modifiedTime;
  final int? size;

  FileItem({
    required this.path,
    required this.name,
    required this.type,
    this.modifiedTime,
    this.size,
  });

  factory FileItem.fromFile(FileSystemEntity entity) {
    final File file = entity as File;
    final String name = p.basename(entity.path);
    final DateTime modifiedTime = file.statSync().modified;
    final int size = file.statSync().size;

    return FileItem(
      path: entity.path,
      name: name,
      type: FileItemType.file,
      modifiedTime: modifiedTime,
      size: size,
    );
  }

  factory FileItem.fromDirectory(FileSystemEntity entity) {
    final String name = p.basename(entity.path);
    final Directory dir = entity as Directory;
    final DateTime modifiedTime = dir.statSync().modified;

    return FileItem(
      path: entity.path,
      name: name,
      type: FileItemType.directory,
      modifiedTime: modifiedTime,
    );
  }

  String get formattedModifiedTime {
    if (modifiedTime == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy HH:mm').format(modifiedTime!);
  }

  String get formattedSize {
    if (size == null || type == FileItemType.directory) return '';
    
    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    if (size! < 1024 * 1024 * 1024) return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    if (type != FileItemType.file) return '';
    return p.extension(name).toLowerCase();
  }

  static FileItemType getType(FileSystemEntity entity) {
    if (entity is File) return FileItemType.file;
    if (entity is Directory) return FileItemType.directory;
    return FileItemType.unknown;
  }
} 