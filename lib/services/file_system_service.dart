import 'dart:io';
import 'package:logging/logging.dart';

class FileSystemService {
  final _logger = Logger('FileSystemService');

  Future<String> getFileOwner(String path) async {
    try {
      final result = await Process.run('stat', ['-c', '%U', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      _logger.warning('Error getting file owner: $e');
    }
    return 'Unknown';
  }

  Future<String> getFileGroup(String path) async {
    try {
      final result = await Process.run('stat', ['-c', '%G', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      _logger.warning('Error getting file group: $e');
    }
    return 'Unknown';
  }
} 