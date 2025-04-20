import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';

class RenameFileDialog extends StatefulWidget {
  final FileItem fileItem;

  const RenameFileDialog({
    super.key,
    required this.fileItem,
  });

  @override
  State<RenameFileDialog> createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends State<RenameFileDialog> {
  late TextEditingController _nameController;
  String? _errorText;
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the current file name
    _nameController = TextEditingController(text: widget.fileItem.name);
    // Select the name part without the extension for easier editing
    _selectNameWithoutExtension();
  }

  void _selectNameWithoutExtension() {
    if (widget.fileItem.type == FileItemType.file) {
      final fileName = widget.fileItem.name;
      final extension = p.extension(fileName);
      if (extension.isNotEmpty) {
        // Select just the filename part, not the extension
        final nameWithoutExt = fileName.substring(0, fileName.length - extension.length);
        _nameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: nameWithoutExt.length,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _renameFile() async {
    final newName = _nameController.text;
    
    // Basic validation
    if (newName.isEmpty) {
      setState(() {
        _errorText = 'Name cannot be empty';
      });
      return;
    }

    if (newName == widget.fileItem.name) {
      // No change, just close the dialog
      Navigator.of(context).pop();
      return;
    }
    
    // Check for invalid characters
    if (newName.contains(RegExp(r'[/\\:*?"<>|]'))) {
      setState(() {
        _errorText = 'Name contains invalid characters';
      });
      return;
    }

    setState(() {
      _isRenaming = true;
      _errorText = null;
    });

    // Get directory and build new path
    final directory = p.dirname(widget.fileItem.path);
    final newPath = p.join(directory, newName);
    
    // Check if file with new name already exists
    if (await File(newPath).exists() || await Directory(newPath).exists()) {
      setState(() {
        _errorText = 'A file or folder with this name already exists';
        _isRenaming = false;
      });
      return;
    }

    try {
      // Perform the rename
      if (widget.fileItem.type == FileItemType.file) {
        final file = File(widget.fileItem.path);
        await file.rename(newPath);
      } else if (widget.fileItem.type == FileItemType.directory) {
        final dir = Directory(widget.fileItem.path);
        await dir.rename(newPath);
      }
      
      // Close dialog and return success
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = 'Failed to rename: $e';
          _isRenaming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Rename'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter a new name for "${widget.fileItem.name}"',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _nameController.clear();
                },
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => _renameFile(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isRenaming ? null : _renameFile,
          child: _isRenaming
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Rename'),
        ),
      ],
    );
  }
} 