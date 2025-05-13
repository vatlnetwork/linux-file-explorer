import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';
import '../models/file_item.dart';

class FileRepository {
  final _logger = Logger('FileRepository');
  final _directoryController = StreamController<List<FileItem>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  Stream<List<FileItem>> get directoryStream => _directoryController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  Future<void> listDirectory(String path) async {
    try {
      final directory = Directory(path);
      final entities = await directory.list().toList();
      final items = <FileItem>[];
      
      for (final entity in entities) {
        if (p.basename(entity.path).startsWith('.')) continue;
        
        try {
          final item = await FileItem.fromEntity(entity);
          items.add(item);
        } catch (e) {
          _logger.warning('Error processing file ${entity.path}: $e');
        }
      }
      
      items.sort((a, b) {
        if (a.type == FileItemType.directory && b.type != FileItemType.directory) return -1;
        if (a.type != FileItemType.directory && b.type == FileItemType.directory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      _directoryController.add(items);
    } catch (e) {
      _errorController.add('Error listing directory: $e');
    }
  }
  
  void dispose() {
    _directoryController.close();
    _errorController.close();
  }
} 