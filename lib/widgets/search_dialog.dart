import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../models/file_item.dart';
import 'dart:async';

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
  SearchScope _searchScope = SearchScope.currentDirectory;
  bool _isSearching = false;
  String _searchStatus = '';
  int _searchProgress = 0;
  int _searchTotal = 0;
  Timer? _searchTimeout;
  Timer? _debounceTimer;
  List<FileItem> _searchResults = [];

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

    // Cancel any existing search
    widget.fileService.cancelSearch();

    // Set a timeout to cancel the search if it takes too long
    _searchTimeout?.cancel();
    _searchTimeout = Timer(const Duration(seconds: 35), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchStatus = 'Search timed out. Try a more specific search.';
        });
        widget.fileService.cancelSearch();
      }
    });

    try {
      List<FileItem> results;
      switch (_searchScope) {
        case SearchScope.currentDirectory:
          results = await widget.fileService.searchInDirectory(
            widget.currentDirectory,
            _searchController.text,
          );
          break;
        case SearchScope.directoryAndSubdirectories:
          results = await widget.fileService.searchInDirectoryAndSubdirectories(
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
          );
          break;
        case SearchScope.allFiles:
          results = await widget.fileService.searchAllFiles(
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
          );
          break;
      }

      _searchTimeout?.cancel();

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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search bar with icon and menu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search files...',
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  PopupMenuButton<SearchScope>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (scope) {
                      setState(() {
                        _searchScope = scope;
                      });
                      _performSearch();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: SearchScope.currentDirectory,
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              size: 20,
                              color: _searchScope == SearchScope.currentDirectory
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Search in current directory',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SearchScope.directoryAndSubdirectories,
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 20,
                              color: _searchScope == SearchScope.directoryAndSubdirectories
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Search in directory and subdirectories',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SearchScope.allFiles,
                        child: Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 20,
                              color: _searchScope == SearchScope.allFiles
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Search in all files',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
            if (_searchStatus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _searchStatus,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_searchTotal > 0)
              LinearProgressIndicator(
                value: _searchTotal > 0 ? _searchProgress / _searchTotal : null,
              ),
            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Start typing to search'
                                : 'No results found',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            return ListTile(
                              leading: Icon(
                                item.type == FileItemType.directory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: colorScheme.primary,
                              ),
                              title: Text(item.name),
                              subtitle: Text(item.path),
                              onTap: () {
                                Navigator.pop(context, item);
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

enum SearchScope {
  currentDirectory,
  directoryAndSubdirectories,
  allFiles,
} 