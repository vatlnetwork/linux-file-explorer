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
} 