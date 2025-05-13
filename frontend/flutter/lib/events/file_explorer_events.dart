import '../models/file_item.dart';
import '../states/file_explorer_state.dart';
import '../commands/file_explorer_commands.dart';

class FileExplorerEvents {
  final FileExplorerState _state;
  final FileExplorerCommands _commands;
  
  FileExplorerEvents(this._state, this._commands);
  
  void onItemTap(FileItem item) {
    if (item.type == FileItemType.directory) {
      _state.setCurrentPath(item.path);
    } else {
      final newSelection = {..._state.selectedItemsPaths, item.path};
      _state.setSelectedItems(newSelection);
    }
  }
  
  void onItemDoubleTap(FileItem item) {
    if (item.type == FileItemType.directory) {
      _state.setCurrentPath(item.path);
    }
  }
  
  void onItemLongPress(FileItem item) {
    final newSelection = {..._state.selectedItemsPaths, item.path};
    _state.setSelectedItems(newSelection);
  }
  
  void onSelectionClear() {
    _state.clearSelection();
  }
  
  void onSelectionAdd(String path) {
    _state.addToSelection(path);
  }
  
  void onSelectionRemove(String path) {
    _state.removeFromSelection(path);
  }
  
  Future<void> onCreateDirectory(String name) async {
    await _commands.createDirectory(name);
  }
  
  Future<void> onCreateFile(String name) async {
    await _commands.createFile(name);
  }
  
  Future<void> onDeleteSelected() async {
    await _commands.deleteSelected();
  }
  
  Future<void> onCopySelected(String targetDir) async {
    await _commands.copySelected(targetDir);
  }
  
  Future<void> onMoveSelected(String targetDir) async {
    await _commands.moveSelected(targetDir);
  }
  
  Future<void> onRename(String path, String newName) async {
    await _commands.rename(path, newName);
  }
  
  void onNavigateBack() {
    _state.navigateBack();
  }
  
  void onNavigateForward() {
    _state.navigateForward();
  }
  
  void onToggleBookmarkSidebar() {
    _state.toggleBookmarkSidebar();
  }
} 