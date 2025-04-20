import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/tag.dart';
import '../services/tags_service.dart';
import '../widgets/file_list_tile.dart';
import '../widgets/empty_state.dart';

class TagsViewScreen extends StatefulWidget {
  static const String routeName = '/tags';

  const TagsViewScreen({super.key});

  @override
  State<TagsViewScreen> createState() => _TagsViewScreenState();
}

class _TagsViewScreenState extends State<TagsViewScreen> {
  String? _selectedTagId;
  String _searchQuery = '';
  bool _sortByUsage = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
        actions: [
          IconButton(
            icon: Icon(_sortByUsage ? Icons.sort : Icons.sort_by_alpha),
            onPressed: () {
              setState(() {
                _sortByUsage = !_sortByUsage;
              });
            },
            tooltip: _sortByUsage ? 'Sort by usage' : 'Sort alphabetically',
          ),
        ],
      ),
      body: Consumer<TagsService>(
        builder: (context, tagsService, _) {
          var tags = tagsService.availableTags;
          
          // Get tag usage counts for sorting and display
          final Map<String, int> tagUsageCounts = {};
          for (final tag in tags) {
            tagUsageCounts[tag.id] = tagsService.getFilesWithTag(tag.id).length;
          }
          
          // Sort tags
          if (_sortByUsage) {
            tags = List.from(tags)
              ..sort((a, b) => tagUsageCounts[b.id]!.compareTo(tagUsageCounts[a.id]!));
          } else {
            tags = List.from(tags)
              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          }
          
          // Filter tags if search is active
          if (_searchQuery.isNotEmpty) {
            tags = tags.where((tag) => 
              tag.name.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }

          if (tags.isEmpty) {
            return const EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'No Tags Found',
              message: 'You haven\'t created any tags yet or no tags match your search.',
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tags...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      // Clear selection if the selected tag is filtered out
                      if (_selectedTagId != null && 
                          !tags.any((tag) => tag.id == _selectedTagId)) {
                        _selectedTagId = null;
                      }
                    });
                  },
                ),
              ),
              
              // Tags and files view
              Expanded(
                child: Row(
                  children: [
                    // Tags sidebar
                    SizedBox(
                      width: 250,
                      child: Material(
                        elevation: 1,
                        child: ListView.builder(
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            final count = tagUsageCounts[tag.id] ?? 0;
                            
                            return ListTile(
                              leading: Icon(
                                Icons.local_offer,
                                color: tag.color,
                              ),
                              title: Text(tag.name),
                              subtitle: Text('$count ${count == 1 ? 'file' : 'files'}'),
                              selected: _selectedTagId == tag.id,
                              onTap: () {
                                setState(() {
                                  _selectedTagId = tag.id;
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: count > 0 ? null : () => _confirmDeleteTag(context, tagsService, tag),
                                tooltip: count > 0 ? 'Cannot delete tag in use' : 'Delete tag',
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Files with the selected tag
                    Expanded(
                      child: _selectedTagId == null
                          ? const Center(
                              child: Text('Select a tag to view associated files'),
                            )
                          : _buildFilesForTag(tagsService, _selectedTagId!),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTagDialog(context),
        tooltip: 'Create New Tag',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteTag(BuildContext context, TagsService tagsService, Tag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete the tag "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              tagsService.deleteTag(tag.id);
              Navigator.pop(context);
              setState(() {
                if (_selectedTagId == tag.id) {
                  _selectedTagId = null;
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Tag'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.amber,
                    Colors.cyan,
                    Colors.indigo,
                  ].map((color) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: color == selectedColor
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: color == selectedColor
                              ? [BoxShadow(color: Colors.black38, blurRadius: 2)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    final tagsService = Provider.of<TagsService>(context, listen: false);
                    tagsService.createTag(name, selectedColor);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    ).then((_) => nameController.dispose());
  }

  Widget _buildFilesForTag(TagsService tagsService, String tagId) {
    final files = tagsService.getFilesWithTag(tagId);
    final tag = tagsService.availableTags.firstWhere((t) => t.id == tagId);

    if (files.isEmpty) {
      return EmptyState(
        icon: Icons.insert_drive_file_outlined,
        title: 'No Files',
        message: 'No files have been tagged with "${tag.name}"',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: tag.color),
              const SizedBox(width: 8),
              Text(
                'Files tagged with "${tag.name}" (${files.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final path = files[index];
              final file = File(path);
              
              if (!file.existsSync()) {
                // Skip files that no longer exist
                return const SizedBox.shrink();
              }
              
              return FileListTile(
                file: file,
                onTap: () {
                  // Navigate to the file in the explorer
                  Navigator.pop(context, {
                    'action': 'navigate',
                    'path': path,
                  });
                },
                onDoubleTap: () {
                  // Open the file and return
                  Navigator.pop(context, {
                    'action': 'open',
                    'path': path,
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 