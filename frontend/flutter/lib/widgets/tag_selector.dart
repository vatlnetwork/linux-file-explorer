import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../services/tags_service.dart';
import '../services/theme_service.dart';
import 'package:path/path.dart' as p;

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
    final themeService = Provider.of<ThemeService>(context);
    final isMacOS = themeService.themePreset == ThemePreset.macos;

    return Consumer<TagsService>(
      builder: (context, tagsService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          padding: EdgeInsets.all(isMacOS ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3C4043) // Dark mode background
                    : Colors.white, // Light mode background
            borderRadius: BorderRadius.circular(isMacOS ? 6.0 : 8.0),
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
                    spacing: isMacOS ? 6 : 8,
                    runSpacing: isMacOS ? 6 : 8,
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
                            horizontal: isMacOS ? 8 : 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              isMacOS ? 4 : 6,
                            ),
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
                            horizontal: isMacOS ? 8 : 12,
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
                  spacing: isMacOS ? 6 : 8,
                  runSpacing: isMacOS ? 6 : 8,
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
    final themeService = Provider.of<ThemeService>(context);
    final isMacOS = themeService.themePreset == ThemePreset.macos;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final tagColor = tag.color;
    final backgroundColor = Color.fromRGBO(
      (tagColor.r * 255).round() & 0xff,
      (tagColor.g * 255).round() & 0xff,
      (tagColor.b * 255).round() & 0xff,
      isMacOS ? (isDarkMode ? 0.2 : 0.15) : 0.2,
    );

    return Chip(
      label: Text(tag.name, style: TextStyle(fontSize: isMacOS ? 12 : 13)),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(
        color: tagColor,
        fontWeight: isMacOS ? FontWeight.w500 : FontWeight.normal,
      ),
      deleteIcon: Icon(Icons.close, size: isMacOS ? 14 : 16),
      labelPadding: EdgeInsets.symmetric(horizontal: isMacOS ? 6 : 8),
      padding: EdgeInsets.symmetric(horizontal: isMacOS ? 6 : 8),
      side: isMacOS && !isDarkMode ? BorderSide.none : null,
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
    final themeService = Provider.of<ThemeService>(context);
    final isMacOS = themeService.themePreset == ThemePreset.macos;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get files for this tag
    final taggedFiles = tagsService.getFilesWithTag(tag.id);
    final fileCount = taggedFiles.length;

    // Create tooltip content
    String tooltipContent = 'No files tagged';
    if (fileCount > 0) {
      tooltipContent = 'Tagged files (${taggedFiles.length}):\n';
      final filesToShow = taggedFiles
          .take(5)
          .map((path) => '• ${p.basename(path)}')
          .join('\n');
      tooltipContent += filesToShow;
      if (fileCount > 5) {
        tooltipContent += '\n...and ${fileCount - 5} more';
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
          padding: EdgeInsets.symmetric(
            horizontal: isMacOS ? 6 : 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: tag.color.withValues(
              alpha: isMacOS ? (isDarkMode ? 0.2 : 0.15) : 0.2,
              red: tag.color.r,
              green: tag.color.g,
              blue: tag.color.b,
            ),
            borderRadius: BorderRadius.circular(4),
            border:
                isMacOS && !isDarkMode
                    ? null
                    : Border.all(
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
                  fontSize: isMacOS ? 12 : 13,
                  color: tag.color,
                  fontWeight: isMacOS ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: tag.color.withValues(
                    alpha: isMacOS ? (isDarkMode ? 0.2 : 0.15) : 0.2,
                    red: tag.color.r,
                    green: tag.color.g,
                    blue: tag.color.b,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fileCount.toString(),
                  style: TextStyle(
                    fontSize: isMacOS ? 10 : 11,
                    color: tag.color,
                    fontWeight: isMacOS ? FontWeight.w500 : FontWeight.normal,
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
