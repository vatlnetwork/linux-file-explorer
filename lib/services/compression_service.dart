import 'dart:io';
import 'package:path/path.dart' as p;

class CompressionService {
  static final CompressionService _instance = CompressionService._internal();
  factory CompressionService() => _instance;
  CompressionService._internal();

  /// Get the correct output path for a compressed file
  String getOutputPath(String sourcePath, {String? customOutputPath}) {
    if (customOutputPath != null) {
      return customOutputPath;
    }
    final baseName = p.basenameWithoutExtension(sourcePath);
    final parentDir = p.dirname(sourcePath);
    return p.join(parentDir, '$baseName.zip');
  }

  /// Compress a file or directory into a ZIP archive
  Future<String> compressToZip(String sourcePath, {int compressionLevel = 6, String? outputPath}) async {
    final sourceFile = File(sourcePath);
    final sourceDir = Directory(sourcePath);
    final finalOutputPath = getOutputPath(sourcePath, customOutputPath: outputPath);

    // Validate compression level
    if (compressionLevel < 0 || compressionLevel > 9) {
      throw Exception('Compression level must be between 0 and 9');
    }

    // Check if source exists
    if (!sourceFile.existsSync() && !sourceDir.existsSync()) {
      throw Exception('Source file or directory does not exist');
    }

    // Check if output file already exists
    if (File(finalOutputPath).existsSync()) {
      throw Exception('Output file already exists');
    }

    try {
      // Determine if source is a file or directory
      final isDirectory = sourceDir.existsSync();
      
      // Build the zip command with appropriate options
      final List<String> args = ['-$compressionLevel'];
      
      if (isDirectory) {
        // For directories, use recursive mode and preserve directory structure
        args.addAll(['-r']);
        // Get the parent directory to ensure proper path structure
        final parentDir = p.dirname(sourcePath);
        final baseName = p.basename(sourcePath);
        args.addAll([finalOutputPath, baseName]);
        
        // Change to parent directory to ensure proper path structure
        final result = await Process.run('zip', args, workingDirectory: parentDir);
        
        if (result.exitCode != 0) {
          // Clean up partial output file if it exists
          if (File(finalOutputPath).existsSync()) {
            await File(finalOutputPath).delete();
          }
          throw Exception('Failed to compress directory: ${result.stderr}');
        }
      } else {
        // For files, preserve the directory structure relative to the parent
        final parentDir = p.dirname(sourcePath);
        final fileName = p.basename(sourcePath);
        args.addAll([finalOutputPath, fileName]);
        
        // Change to parent directory to ensure proper path structure
        final result = await Process.run('zip', args, workingDirectory: parentDir);
        
        if (result.exitCode != 0) {
          // Clean up partial output file if it exists
          if (File(finalOutputPath).existsSync()) {
            await File(finalOutputPath).delete();
          }
          throw Exception('Failed to compress file: ${result.stderr}');
        }
      }

      // Verify the output file was created
      if (!File(finalOutputPath).existsSync()) {
        throw Exception('Compression completed but output file was not created');
      }

      return finalOutputPath;
    } catch (e) {
      // Clean up partial output file if it exists
      if (File(finalOutputPath).existsSync()) {
        await File(finalOutputPath).delete();
      }
      throw Exception('Failed to compress: $e');
    }
  }

  /// Check if a file is a ZIP archive
  bool isZipFile(String path) {
    final ext = p.extension(path).toLowerCase();
    return ext == '.zip';
  }

  /// Get the name of the ZIP file that would be created for a given path
  String getZipFileName(String path) {
    final baseName = p.basenameWithoutExtension(path);
    return '$baseName.zip';
  }

  /// Get the size of a file or directory before compression
  Future<int> getUncompressedSize(String path) async {
    final file = File(path);
    final dir = Directory(path);
    
    if (file.existsSync()) {
      return file.lengthSync();
    } else if (dir.existsSync()) {
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    }
    throw Exception('Path does not exist');
  }

  /// Get the size of a compressed file
  Future<int> getCompressedSize(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Compressed file does not exist');
    }
    return file.lengthSync();
  }
} 