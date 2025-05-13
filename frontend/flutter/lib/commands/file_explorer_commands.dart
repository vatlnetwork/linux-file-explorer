import '../operations/file_operations.dart';
import '../states/file_explorer_state.dart';
import '../repositories/file_repository.dart';

class FileExplorerCommands {
  final FileOperations _operations;
  final FileRepository _repository;
  final FileExplorerState _state;
  
  FileExplorerCommands(this._operations, this._repository, this._state);
  
  Future<void> createDirectory(String name) async {
    try {
      await _operations.createDirectory(_state.currentPath, name);
      await _repository.listDirectory(_state.currentPath);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> createFile(String name) async {
    try {
      await _operations.createFile(_state.currentPath, name);
      await _repository.listDirectory(_state.currentPath);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteSelected() async {
    final paths = _state.selectedItemsPaths.toList();
    for (final path in paths) {
      await _operations.delete(path);
    }
    await _repository.listDirectory(_state.currentPath);
  }
  
  Future<void> copySelected(String targetDir) async {
    final paths = _state.selectedItemsPaths.toList();
    for (final path in paths) {
      await _operations.copy(path, targetDir);
    }
    await _repository.listDirectory(_state.currentPath);
  }
  
  Future<void> rename(String path, String newName) async {
    await _operations.rename(path, newName);
    await _repository.listDirectory(_state.currentPath);
  }
  
  Future<void> moveSelected(String targetDir) async {
    final paths = _state.selectedItemsPaths.toList();
    for (final path in paths) {
      final sourceName = path.split('/').last;
      final targetPath = '$targetDir/$sourceName';
      await _operations.rename(path, targetPath);
    }
    await _repository.listDirectory(_state.currentPath);
  }
  
  Future<String> getNonConflictingName(String path) async {
    return await _operations.getNonConflictingName(path);
  }
} 