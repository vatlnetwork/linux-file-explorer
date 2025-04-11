import 'dart:io';
import 'package:logging/logging.dart';

// Create a logger instance
final _logger = Logger('DiskService');

class DiskSpace {
  final String mountPoint;
  final String fileSystem;
  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  final double usagePercentage;

  DiskSpace({
    required this.mountPoint,
    required this.fileSystem,
    required this.totalBytes,
    required this.usedBytes,
    required this.availableBytes,
    required this.usagePercentage,
  });
}

class DiskService {
  /// Returns disk space information for the given path
  Future<DiskSpace?> getDiskSpaceInfo(String path) async {
    try {
      // Run df command to get disk space information for the given path
      final ProcessResult result = await Process.run('df', ['-B1', path]);
      if (result.exitCode != 0) {
        return null;
      }

      // Parse the df output, expecting a header line and a data line
      final String output = result.stdout.toString();
      final List<String> lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      if (lines.length < 2) {
        return null;
      }

      // Parse the data line with spaces as delimiter
      final List<String> parts = lines[1].split(RegExp(r'\s+'));
      if (parts.length < 6) {
        return null;
      }

      return DiskSpace(
        fileSystem: parts[0],
        totalBytes: int.tryParse(parts[1]) ?? 0,
        usedBytes: int.tryParse(parts[2]) ?? 0,
        availableBytes: int.tryParse(parts[3]) ?? 0,
        usagePercentage: double.tryParse(parts[4].replaceAll('%', '')) ?? 0,
        mountPoint: parts[5],
      );
    } catch (e) {
      _logger.warning('Error getting disk space: $e');
      return null;
    }
  }

  /// Format bytes to human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns a list of the largest files in the given directory
  Future<List<FileSize>> getLargestFiles(String path, {int limit = 20}) async {
    try {
      // Sanitize path to avoid command injection
      final sanitizedPath = path.replaceAll('"', '\\"');
      
      // Run the command with a timeout to prevent hanging
      final result = await Process.run('bash', [
        '-c',
        'find "$sanitizedPath" -type f -not -path "*/\\.*" -print0 2>/dev/null | xargs -0 du -h 2>/dev/null | sort -rh 2>/dev/null | head -n $limit 2>/dev/null || echo ""'
      ]).timeout(const Duration(seconds: 30), onTimeout: () {
        _logger.warning('Command timed out when finding largest files');
        return ProcessResult(0, 1, '', 'Command timed out');
      });
      
      if (result.exitCode != 0) {
        _logger.warning('Error finding largest files: ${result.stderr}');
        return [];
      }

      final String output = result.stdout.toString();
      if (output.isEmpty) {
        return [];
      }
      
      final List<String> lines = output.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      List<FileSize> files = [];
      for (var line in lines) {
        try {
          // The output format is: "SIZE PATH"
          final match = RegExp(r'^(\S+)\s+(.+)$').firstMatch(line);
          if (match != null) {
            final size = match.group(1) ?? '';
            final filePath = match.group(2) ?? '';
            
            // Extract file name from path
            final fileName = filePath.split('/').last;
            
            // Parse bytes from human-readable format if possible
            int? bytes;
            try {
              if (size.endsWith('K')) {
                bytes = (double.parse(size.substring(0, size.length - 1)) * 1024).round();
              } else if (size.endsWith('M')) {
                bytes = (double.parse(size.substring(0, size.length - 1)) * 1024 * 1024).round();
              } else if (size.endsWith('G')) {
                bytes = (double.parse(size.substring(0, size.length - 1)) * 1024 * 1024 * 1024).round();
              } else {
                bytes = int.parse(size);
              }
            } catch (e) {
              // If we can't parse, just use null for bytes
              _logger.warning('Failed to parse size: $size');
            }
            
            files.add(FileSize(
              path: filePath,
              name: fileName,
              sizeBytes: bytes,
              sizeFormatted: size,
            ));
          }
        } catch (e) {
          _logger.warning('Error parsing line "$line": $e');
          // Continue processing other lines
        }
      }
      
      return files;
    } catch (e) {
      _logger.warning('Error getting largest files: $e');
      return [];
    }
  }
}

/// Represents a file with its size information
class FileSize {
  final String path;
  final String name;
  final int? sizeBytes;
  final String sizeFormatted;

  FileSize({
    required this.path,
    required this.name,
    this.sizeBytes,
    required this.sizeFormatted,
  });
} 