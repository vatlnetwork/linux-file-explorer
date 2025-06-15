import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../models/file_item.dart';
import '../services/tags_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';

class SearchDialog extends StatefulWidget {
  final String currentDirectory;
  final FileService fileService;
  final void Function(String) onFileSelected;

  const SearchDialog({
    super.key,
    required this.currentDirectory,
    required this.fileService,
    required this.onFileSelected,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  String _searchStatus = '';
  int _searchProgress = 0;
  int _searchTotal = 0;
  Timer? _searchTimeout;
  Timer? _debounceTimer;
  List<FileItem> _searchResults = [];
  bool _searchInFiles = true;
  String? _selectedFileType;

  final List<String> _fileTypes = [
    'All Files',
    'Text Files',
    'Source Code',
    'Documents',
    'Images',
    'Audio',
    'Video',
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimeout?.cancel();
    _debounceTimer?.cancel();
    widget.fileService.cancelSearch();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchStatus = 'Searching...';
      _searchProgress = 0;
      _searchTotal = 0;
    });

    widget.fileService.cancelSearch();

    try {
      List<FileItem> results = await widget.fileService
          .searchInDirectoryAndSubdirectories(
            widget.currentDirectory,
            _searchController.text,
            onProgress: (progress, total) {
              if (mounted) {
                setState(() {
                  _searchProgress = progress;
                  _searchTotal = total;
                  _searchStatus = 'Searching... ($progress/$total)';
                });
              }
            },
            searchInFiles: _searchInFiles,
            fileType:
                _selectedFileType == 'All Files' ? null : _selectedFileType,
          );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _searchStatus = 'Found ${results.length} results';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchStatus = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor:
          isDarkMode ? colorScheme.surface : colorScheme.background,
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isDarkMode
                        ? colorScheme.surfaceVariant.withOpacity(0.3)
                        : colorScheme.surfaceVariant.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? colorScheme.surface
                              : colorScheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isDarkMode
                                ? colorScheme.outline
                                : colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.manage_search,
                            color: colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? colorScheme.onSurface
                                      : colorScheme.onBackground,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search in files...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        if (_isSearching)
                          IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              widget.fileService.cancelSearch();
                              setState(() {
                                _isSearching = false;
                                _searchStatus = 'Search cancelled';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _searchInFiles,
                        onChanged: (value) {
                          setState(() {
                            _searchInFiles = value;
                            _performSearch();
                          });
                        },
                      ),
                      Text(
                        'Search in file contents',
                        style: TextStyle(
                          color:
                              isDarkMode
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFileType ?? 'All Files',
                            isExpanded: true,
                            items:
                                _fileTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isDarkMode
                                                ? colorScheme.onSurface
                                                : colorScheme.onBackground,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFileType = value;
                                _performSearch();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _searchStatus,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      isDarkMode
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ),
            if (_searchTotal > 0)
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value:
                      _searchTotal > 0 ? _searchProgress / _searchTotal : null,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            Expanded(
              child:
                  _isSearching
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                      : _searchResults.isEmpty
                      ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Type to search in files'
                              : 'No results found',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              item.type == FileItemType.directory
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              color: colorScheme.primary,
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? colorScheme.onSurface
                                        : colorScheme.onBackground,
                              ),
                            ),
                            subtitle: Text(
                              item.path,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onBackground.withOpacity(
                                          0.7,
                                        ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop(item);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
