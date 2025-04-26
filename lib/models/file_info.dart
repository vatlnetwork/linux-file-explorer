import 'dart:io';

class FileInfo {
  final String path;
  final String name;
  final String size;
  final bool isDirectory;
  final File? customIcon;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.isDirectory,
    this.customIcon,
  });

  factory FileInfo.fromFileSystemEntity(FileSystemEntity entity, {File? customIcon}) {
    final path = entity.path;
    final name = path.split('/').last;
    final size = entity is File ? '${entity.lengthSync()} bytes' : '';
    final isDirectory = entity is Directory;

    return FileInfo(
      path: path,
      name: name,
      size: size,
      isDirectory: isDirectory,
      customIcon: customIcon,
    );
  }
} 