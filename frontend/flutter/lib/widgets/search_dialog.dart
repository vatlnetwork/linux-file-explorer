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
  bool _searchByTag = false;
  String? _selectedTagId;

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
    if (_searchController.text.isEmpty && !_searchByTag) {
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

    try {
      List<FileItem> results;
      
      if (_searchByTag && _selectedTagId != null) {
        // Search by tag
        final tagsService = Provider.of<TagsService>(context, listen: false);
        final filesWithTag = tagsService.getFilesWithTag(_selectedTagId!);
        results = await widget.fileService.searchInDirectoryAndSubdirectories(
          widget.currentDirectory,
          '', // Empty search query since we're searching by tag
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
        // Filter results to only include files with the selected tag
        results = results.where((item) => filesWithTag.contains(item.path)).toList();
      } else {
        // Regular search
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
      }

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
            // Search bar with icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _searchByTag,
                        onChanged: (value) {
                          setState(() {
                            _searchByTag = value ?? false;
                            _selectedTagId = null;
                            _performSearch();
                          });
                        },
                      ),
                      const Text('Search by tag'),
                      const SizedBox(width: 16),
                      if (_searchByTag)
                        Expanded(
                          child: Consumer<TagsService>(
                            builder: (context, tagsService, _) {
                              return DropdownButton<String>(
                                value: _selectedTagId,
                                hint: const Text('Select a tag'),
                                isExpanded: true,
                                items: tagsService.availableTags.map((tag) {
                                  return DropdownMenuItem<String>(
                                    value: tag.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.local_offer,
                                          color: tag.color,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(tag.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTagId = value;
                                    _performSearch();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
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
                            _searchController.text.isEmpty && !_searchByTag
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
                            return Consumer<TagsService>(
                              builder: (context, tagsService, _) {
                                final fileTags = tagsService.getTagsForFile(item.path);
                                return ListTile(
                                  leading: Icon(
                                    item.type == FileItemType.directory
                                        ? Icons.folder
                                        : Icons.insert_drive_file,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(item.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.path),
                                      if (fileTags.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: fileTags.map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: tag.color.withAlpha(50),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: tag.color.withAlpha(100),
                                                  width: 0.5,
                                                ),
                                              ),
                                              child: Text(
                                                tag.name,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: tag.color,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, item);
                                  },
                                );
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