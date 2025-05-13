import '../repositories/file_repository.dart';
import '../states/file_explorer_state.dart';
import '../operations/file_operations.dart';
import '../commands/file_explorer_commands.dart';
import '../events/file_explorer_events.dart';
import '../models/file_item.dart';

class FileExplorerViewModel {
  final FileRepository _repository;
  final FileExplorerState _state;
  final FileOperations _operations = FileOperations();
  late final FileExplorerCommands _commands;
  late final FileExplorerEvents _events;
  
  FileExplorerViewModel(this._repository, this._state) {
    _commands = FileExplorerCommands(_operations, _repository, _state);
    _events = FileExplorerEvents(_state, _commands);
    
    _repository.directoryStream.listen((items) {
      _state.setLoading(false);
    });
    
    _repository.errorStream.listen((error) {
      _state.setLoading(false);
      // Error handling can be implemented here
    });
  }
  
  FileExplorerEvents get events => _events;
  Stream<List<FileItem>> get directoryStream => _repository.directoryStream;
  
  Future<void> loadDirectory(String path) async {
    _state.setLoading(true);
    _state.setCurrentPath(path);
    await _repository.listDirectory(path);
  }
  
  void dispose() {
    _repository.dispose();
  }
} 