import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tags_service.dart';

class TagSelector extends StatefulWidget {
  final String filePath;
  final Function(List<Tag>)? onTagsChanged;

  const TagSelector({super.key, required this.filePath, this.onTagsChanged});

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
    final tagsService = Provider.of<TagsService>(context);
    final fileTags = tagsService.getTagsForFile(widget.filePath);
    final availableTags = tagsService.availableTags;
    // Remove themeService and isMacOS logic
    return Consumer<TagsService>(
      builder: (context, tagsService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selected tags
              if (fileTags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        fileTags
                            .map(
                              (tag) => _buildTagChip(context, tag, tagsService),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add new tag
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Add new tag",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onSubmitted:
                            (value) => _addNewTag(context, tagsService),
                        onChanged: (value) {
                          setState(() {}); // Trigger rebuild to update UI
                        },
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
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _addNewTag(context, tagsService),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Available tags
              const Text(
                'Available Tags',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      availableTags
                          .where((tag) => !fileTags.contains(tag))
                          .map(
                            (tag) => _buildAvailableTagChip(
                              context,
                              tag,
                              tagsService,
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChip(BuildContext context, Tag tag, TagsService tagsService) {
    final tagColor = tag.color;
    final backgroundColor = Color.fromRGBO(
      (tagColor.r * 255).round() & 0xff,
      (tagColor.g * 255).round() & 0xff,
      (tagColor.b * 255).round() & 0xff,
      0.2,
    );

    return Chip(
      label: Text(tag.name, style: TextStyle(fontSize: 12)),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: tagColor, fontWeight: FontWeight.normal),
      deleteIcon: Icon(Icons.close, size: 14),
      labelPadding: EdgeInsets.symmetric(horizontal: 6),
      padding: EdgeInsets.symmetric(horizontal: 6),
      onDeleted: () async {
        await tagsService.removeTagFromFile(widget.filePath, tag.id);
        if (widget.onTagsChanged != null) {
          widget.onTagsChanged!(tagsService.getTagsForFile(widget.filePath));
        }
      },
    );
  }

  Widget _buildAvailableTagChip(
    BuildContext context,
    Tag tag,
    TagsService tagsService,
  ) {
    // Get files for this tag
    final taggedFiles = tagsService.getFilesWithTag(tag.id);
    final fileCount = taggedFiles.length;

    // Create tooltip content
    String tooltipContent = 'No files tagged';
    if (fileCount > 0) {
      tooltipContent = 'Tagged files (${taggedFiles.length}):\n';
      final filesToShow = taggedFiles
          .take(5)
          .map((path) => '•  p.basename(path)')
          .join('\n');
      tooltipContent += filesToShow;
      if (fileCount > 5) {
        tooltipContent += '\n...and  (fileCount - 5) more';
      }
    }

    return Tooltip(
      message: tooltipContent,
      padding: const EdgeInsets.all(8),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () async {
          await tagsService.addTagToFile(widget.filePath, tag);
          if (widget.onTagsChanged != null) {
            widget.onTagsChanged!(tagsService.getTagsForFile(widget.filePath));
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: tag.color.withValues(
              alpha: 0.2,
              red: tag.color.r,
              green: tag.color.g,
              blue: tag.color.b,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? tag.color.withAlpha(100)
                      : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.name,
                style: TextStyle(
                  fontSize: 12,
                  color: tag.color,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: tag.color.withValues(
                    alpha: 0.2,
                    red: tag.color.r,
                    green: tag.color.g,
                    blue: tag.color.b,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fileCount.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: tag.color,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectColor(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
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
