import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../models/file_item.dart';
import '../services/tags_service.dart';
import '../models/tag.dart';
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
  final TextEditingController _tagSearchController = TextEditingController();
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
  // ignore: prefer_final_fields
  List<Tag> _selectedTags = [];
  String _tagSearchQuery = '';

  final List<String> _fileTypes = [
    'All Files',
    'Text Files',
    'Source Code',
    'Documents',
    'Images',
    'Audio',
    'Video',
    'Archives',
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tagSearchController.dispose();
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
    if (_searchController.text.isEmpty && _selectedTags.isEmpty) {
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
            tags: _selectedTags.isEmpty ? null : _selectedTags,
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

  List<Tag> _getFilteredTags(List<Tag> allTags) {
    if (_tagSearchQuery.isEmpty) return allTags;
    final query = _tagSearchQuery.toLowerCase();
    return allTags
        .where((tag) => tag.name.toLowerCase().contains(query))
        .toList();
  }

  Widget _buildTagChip(Tag tag, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      label: Text(tag.name),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : tag.color,
      ),
      backgroundColor: tag.color.withAlpha(26),
      selectedColor: tag.color,
      checkmarkColor: Colors.white,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.removeWhere((t) => t.id == tag.id);
          }
          _performSearch();
        });
      },
    );
  }

  Widget _buildTagsSection(
    TagsService tagsService,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    final filteredTags = _getFilteredTags(tagsService.availableTags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by tags:',
          style: TextStyle(
            fontSize: 12,
            color:
                isDarkMode
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withAlpha(179),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? colorScheme.surfaceContainer.withAlpha(77)
                    : colorScheme.surfaceContainer.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isDarkMode ? colorScheme.outline : colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 16,
                color:
                    isDarkMode
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface.withAlpha(179),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tagSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search tags...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color:
                          isDarkMode
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurface.withAlpha(179),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withAlpha(179),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _tagSearchQuery = value;
                    });
                  },
                ),
              ),
              if (_tagSearchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _tagSearchQuery = '';
                      _tagSearchController.clear();
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (filteredTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No tags found',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDarkMode
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface.withAlpha(179),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                filteredTags.map((tag) {
                  return _buildTagChip(
                    tag,
                    _selectedTags.any((t) => t.id == tag.id),
                  );
                }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final tagsService = Provider.of<TagsService>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: colorScheme.surface,
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
                        ? colorScheme.surfaceContainer.withAlpha(77)
                        : colorScheme.surfaceContainer.withAlpha(26),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? colorScheme.surfaceContainer.withAlpha(77)
                              : colorScheme.surfaceContainer.withAlpha(26),
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
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface.withAlpha(179),
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
                                  : colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFileType ?? 'All Files',
                              isExpanded: true,
                              dropdownColor:
                                  isDarkMode
                                      ? colorScheme.surfaceContainer
                                      : colorScheme.surfaceContainer,
                              menuMaxHeight: 300,
                              borderRadius: BorderRadius.circular(12),
                              items:
                                  _fileTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDarkMode
                                                    ? colorScheme
                                                        .onSurfaceVariant
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                          ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTagsSection(tagsService, isDarkMode, colorScheme),
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
                          : colorScheme.onSurface.withAlpha(179),
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
                  backgroundColor: colorScheme.surfaceContainer,
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
                          _searchController.text.isEmpty &&
                                  _selectedTags.isEmpty
                              ? 'Type to search in files or select tags'
                              : 'No results found',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final itemTags = tagsService.getTagsForFile(
                            item.path,
                          );

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
                                        ? colorScheme.onSurfaceVariant
                                        : colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.path,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isDarkMode
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface.withAlpha(
                                              179,
                                            ),
                                  ),
                                ),
                                if (itemTags.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children:
                                        itemTags.map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: tag.color.withAlpha(26),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: tag.color.withAlpha(77),
                                                width: 1,
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
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ],
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
