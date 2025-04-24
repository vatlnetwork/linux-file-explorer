import 'dart:io';
import 'package:path/path.dart' as p;

class FileSystemService {
  Future<String> getFileOwner(String path) async {
    try {
      final result = await Process.run('stat', ['-c', '%U', path]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      print('Error getting file owner: $e');
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
      print('Error getting file group: $e');
    }
    return 'Unknown';
  }
} 