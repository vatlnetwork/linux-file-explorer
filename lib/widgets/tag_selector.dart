import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tags_service.dart';

class TagSelector extends StatefulWidget {
  final String filePath;
  final Function(List<Tag>)? onTagsChanged;
  
  const TagSelector({
    super.key,
    required this.filePath,
    this.onTagsChanged,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final TextEditingController _tagController = TextEditingController();
  Color _selectedColor = Colors.blue;
  
  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<TagsService>(
      builder: (context, tagsService, _) {
        final fileTags = tagsService.getTagsForFile(widget.filePath);
        final availableTags = tagsService.availableTags;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected tags
            if (fileTags.isNotEmpty) ...[
              const Text(
                'Tags',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: fileTags
                    .map((tag) => _buildTagChip(context, tag, tagsService))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add new tag
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add a tag...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _selectColor(context),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addNewTag(context, tagsService),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Available tags
            const Text(
              'Available Tags',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableTags
                  .where((tag) => !fileTags.contains(tag))
                  .map((tag) => _buildAvailableTagChip(context, tag, tagsService))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildTagChip(BuildContext context, Tag tag, TagsService tagsService) {
    return Chip(
      label: Text(tag.name),
      backgroundColor: tag.color.withOpacity(0.2),
      labelStyle: TextStyle(color: tag.color),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () async {
        await tagsService.removeTagFromFile(widget.filePath, tag.id);
        if (widget.onTagsChanged != null) {
          widget.onTagsChanged!(tagsService.getTagsForFile(widget.filePath));
        }
      },
    );
  }
  
  Widget _buildAvailableTagChip(BuildContext context, Tag tag, TagsService tagsService) {
    return InkWell(
      onTap: () async {
        await tagsService.addTagToFile(widget.filePath, tag);
        if (widget.onTagsChanged != null) {
          widget.onTagsChanged!(tagsService.getTagsForFile(widget.filePath));
        }
      },
      child: Chip(
        label: Text(tag.name),
        backgroundColor: tag.color.withOpacity(0.1),
        labelStyle: TextStyle(color: tag.color),
      ),
    );
  }
  
  void _selectColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a color'),
        children: [
          for (final color in [
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
          ])
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  _selectedColor = color;
                });
                Navigator.of(context).pop();
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_getColorName(color)),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  String _getColorName(Color color) {
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.red) return 'Red';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.amber) return 'Amber';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.indigo) return 'Indigo';
    return 'Unknown';
  }
  
  void _addNewTag(BuildContext context, TagsService tagsService) async {
    final name = _tagController.text.trim();
    if (name.isEmpty) return;
    
    final tag = await tagsService.createTag(name, _selectedColor);
    await tagsService.addTagToFile(widget.filePath, tag);
    
    if (widget.onTagsChanged != null) {
      widget.onTagsChanged!(tagsService.getTagsForFile(widget.filePath));
    }
    
    _tagController.clear();
  }
} 