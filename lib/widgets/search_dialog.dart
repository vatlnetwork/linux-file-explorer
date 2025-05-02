import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/file_service.dart';
import '../models/file_item.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<FileItem> _searchResults = [];
  SearchScope _searchScope = SearchScope.currentDirectory;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final fileService = Provider.of<FileService>(context, listen: false);
    List<FileItem> results = [];

    switch (_searchScope) {
      case SearchScope.currentDirectory:
        results = await fileService.searchInDirectory(
          fileService.currentDirectory,
          _searchQuery,
        );
        break;
      case SearchScope.directoryAndSubdirectories:
        results = await fileService.searchInDirectoryAndSubdirectories(
          fileService.currentDirectory,
          _searchQuery,
        );
        break;
      case SearchScope.allFiles:
        results = await fileService.searchAllFiles(_searchQuery);
        break;
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _performSearch();
                      },
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
                ],
              ),
            ),
            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
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