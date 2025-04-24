import 'dart:io';
import 'package:path/path.dart' as p;

class CompressionService {
  static final CompressionService _instance = CompressionService._internal();
  factory CompressionService() => _instance;
  CompressionService._internal();

  /// Compress a file or directory into a ZIP archive
  Future<String> compressToZip(String sourcePath) async {
    final sourceFile = File(sourcePath);
    final sourceDir = Directory(sourcePath);
    final outputPath = '${sourcePath}.zip';

    // Check if source exists
    if (!sourceFile.existsSync() && !sourceDir.existsSync()) {
      throw Exception('Source file or directory does not exist');
    }

    // Check if output file already exists
    if (File(outputPath).existsSync()) {
      throw Exception('Output file already exists');
    }

    try {
      // Use the zip command to create the archive
      final result = await Process.run('zip', ['-r', outputPath, sourcePath]);
      
      if (result.exitCode != 0) {
        throw Exception('Failed to compress: ${result.stderr}');
      }

      return outputPath;
    } catch (e) {
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
    return '${p.basename(path)}.zip';
  }
} 