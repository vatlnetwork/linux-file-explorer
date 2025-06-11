import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/tag.dart';
import '../services/tags_service.dart';
import '../widgets/empty_state.dart';
import 'package:path/path.dart' as p;

class TagsViewScreen extends StatefulWidget {
  static const String routeName = '/tags';

  const TagsViewScreen({super.key});

  @override
  State<TagsViewScreen> createState() => _TagsViewScreenState();
}

class _TagsViewScreenState extends State<TagsViewScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedTagId;
  String _searchQuery = '';
  bool _sortByUsage = false;
  late AnimationController _animationController;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF2D2E31) : Colors.white;
    final borderColor =
        isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final sidebarColor =
        isDarkMode ? const Color(0xFF252525) : const Color(0xFFF0F0F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Sidebar spanning full height
          Consumer<TagsService>(
            builder: (context, tagsService, _) {
              var tags = tagsService.availableTags;
              final tagUsageCounts = _getTagUsageCounts(tagsService, tags);

              tags = _sortTags(tags, tagUsageCounts);
              if (_searchQuery.isNotEmpty) {
                tags = _filterTags(tags);
              }

              return Container(
                width: 220,
                decoration: BoxDecoration(color: sidebarColor),
                child: Column(
                  children: [
                    _buildSearchBar(isDarkMode),
                    Expanded(
                      child: _buildTagsList(
                        tags,
                        tagUsageCounts,
                        isDarkMode,
                        cardColor,
                        borderColor,
                        tagsService,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Main content area with its own header
          Expanded(
            child: Column(
              children: [
                // Title bar in main content
                Container(
                  height: 40,
                  color: backgroundColor,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 18),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Tags',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _sortByUsage ? Icons.sort : Icons.sort_by_alpha,
                          size: 18,
                        ),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip:
                            _sortByUsage
                                ? 'Sort by usage'
                                : 'Sort alphabetically',
                        onPressed:
                            () => setState(() => _sortByUsage = !_sortByUsage),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: 'Create new tag',
                        onPressed: () => _showCreateTagDialog(context),
                      ),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Consumer<TagsService>(
                    builder: (context, tagsService, _) {
                      return _buildTagContent(
                        tagsService,
                        isDarkMode,
                        cardColor,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: 'Search tags...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: const Icon(Icons.search, size: 16),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 24,
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor:
              isDarkMode ? const Color(0xFF2D2E31) : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          isDense: true,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildTagsList(
    List<Tag> tags,
    Map<String, int> tagUsageCounts,
    bool isDarkMode,
    Color cardColor,
    Color borderColor,
    TagsService tagsService,
  ) {
    if (tags.isEmpty) {
      return SizedBox(
        width: 280,
        child: Center(
          child: EmptyState(
            icon: Icons.local_offer_outlined,
            title: 'No Tags Found',
            message:
                _searchQuery.isNotEmpty
                    ? 'No tags match your search'
                    : 'Create your first tag to get started',
          ),
        ),
      );
    }

    return Container(
      width: 220,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final count = tagUsageCounts[tag.id] ?? 0;
          final isSelected = tag.id == _selectedTagId;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedTagId = tag.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: tag.color.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.local_offer,
                        color: tag.color,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            '$count items',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 16),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        onPressed:
                            () => _showTagOptions(context, tagsService, tag),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTagContent(
    TagsService tagsService,
    bool isDarkMode,
    Color cardColor,
  ) {
    if (_selectedTagId == null) {
      return Expanded(
        child: Center(
          child: EmptyState(
            icon: Icons.folder_outlined,
            title: 'No Tag Selected',
            message: 'Select a tag to view tagged files',
          ),
        ),
      );
    }

    final tag = tagsService.availableTags.firstWhere(
      (t) => t.id == _selectedTagId,
    );
    final files = tagsService.getFilesWithTag(_selectedTagId!);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tag.color.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_offer, color: tag.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${files.length} ${files.length == 1 ? 'file' : 'files'} tagged',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tagged Files',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                files.isEmpty
                    ? Center(
                      child: EmptyState(
                        icon: Icons.insert_drive_file_outlined,
                        title: 'No Files Tagged',
                        message: 'No files have been tagged with "${tag.name}"',
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final path = files[index];
                        final file = File(path);

                        if (!file.existsSync()) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            leading: _getFileIcon(file),
                            title: Text(
                              p.basename(file.path),
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              p.dirname(file.path),
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.folder_open_outlined),
                                  tooltip: 'Open containing folder',
                                  onPressed: () {
                                    // Navigate to the folder containing this file
                                    Navigator.pushNamed(
                                      context,
                                      '/',
                                      arguments: {
                                        'initialPath': p.dirname(file.path),
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.local_offer_outlined),
                                  tooltip: 'Manage tags',
                                  onPressed: () {
                                    _showFileTagsDialog(
                                      context,
                                      file,
                                      tagsService,
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // Open the file using default application
                              Process.start('xdg-open', [file.path]);
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _getFileIcon(File file) {
    final ext = p.extension(file.path).toLowerCase();
    IconData iconData;
    Color iconColor;

    if (FileSystemEntity.isDirectorySync(file.path)) {
      iconData = Icons.folder;
      iconColor = Colors.amber;
    } else if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
    ].contains(ext)) {
      iconData = Icons.image;
      iconColor = Colors.blue;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      iconData = Icons.movie;
      iconColor = Colors.red;
    } else if (['.mp3', '.wav', '.ogg', '.flac'].contains(ext)) {
      iconData = Icons.music_note;
      iconColor = Colors.purple;
    } else if (['.pdf'].contains(ext)) {
      iconData = Icons.picture_as_pdf;
      iconColor = Colors.red;
    } else if (['.doc', '.docx'].contains(ext)) {
      iconData = Icons.description;
      iconColor = Colors.blue;
    } else if (['.xls', '.xlsx', '.csv'].contains(ext)) {
      iconData = Icons.table_chart;
      iconColor = Colors.green;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      iconData = Icons.slideshow;
      iconColor = Colors.orange;
    } else if (['.zip', '.rar', '.tar', '.gz'].contains(ext)) {
      iconData = Icons.archive;
      iconColor = Colors.brown;
    } else {
      iconData = Icons.insert_drive_file;
      iconColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Map<String, int> _getTagUsageCounts(TagsService tagsService, List<Tag> tags) {
    final Map<String, int> counts = {};
    for (final tag in tags) {
      counts[tag.id] = tagsService.getFilesWithTag(tag.id).length;
    }
    return counts;
  }

  List<Tag> _sortTags(List<Tag> tags, Map<String, int> tagUsageCounts) {
    final sortedTags = List<Tag>.from(tags);
    if (_sortByUsage) {
      sortedTags.sort(
        (a, b) =>
            (tagUsageCounts[b.id] ?? 0).compareTo(tagUsageCounts[a.id] ?? 0),
      );
    } else {
      sortedTags.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    return sortedTags;
  }

  List<Tag> _filterTags(List<Tag> tags) {
    return tags
        .where(
          (tag) => tag.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showTagOptions(BuildContext context, TagsService tagsService, Tag tag) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor:
                isDarkMode ? const Color(0xFF2D2E31) : Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text('Tag Options: ${tag.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rename Tag'),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameTagDialog(context, tagsService, tag);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete Tag',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteTag(context, tagsService, tag);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showRenameTagDialog(
    BuildContext context,
    TagsService tagsService,
    Tag tag,
  ) {
    final TextEditingController controller = TextEditingController(
      text: tag.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Tag'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tag Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != tag.name) {
                    tagsService.renameTag(tag.id, newName);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Rename'),
              ),
            ],
          ),
    ).then((_) => controller.dispose());
  }

  void _confirmDeleteTag(
    BuildContext context,
    TagsService tagsService,
    Tag tag,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Tag'),
            content: Text(
              'Are you sure you want to delete the tag "${tag.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  tagsService.deleteTag(tag.id);
                  if (_selectedTagId == tag.id) {
                    setState(() => _selectedTagId = null);
                  }
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
      builder:
          (context) => StatefulBuilder(
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
                      children:
                          [
                                Colors.blue,
                                Colors.green,
                                Colors.red,
                                Colors.orange,
                                Colors.purple,
                                Colors.cyan,
                                Colors.pink,
                                Colors.amber,
                                Colors.indigo,
                                Colors.teal,
                              ]
                              .map(
                                (color) => InkWell(
                                  onTap:
                                      () =>
                                          setState(() => selectedColor = color),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border:
                                          color == selectedColor
                                              ? Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              )
                                              : null,
                                      boxShadow:
                                          color == selectedColor
                                              ? [
                                                BoxShadow(
                                                  color: Colors.black38,
                                                  blurRadius: 4,
                                                ),
                                              ]
                                              : null,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        final tagsService = Provider.of<TagsService>(
                          context,
                          listen: false,
                        );
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

  void _showFileTagsDialog(
    BuildContext context,
    File file,
    TagsService tagsService,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2D2E31) : Colors.white;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              final fileTags = tagsService.getTagsForFile(file.path);
              final availableTags = tagsService.availableTags;

              return AlertDialog(
                backgroundColor: cardColor,
                surfaceTintColor: Colors.transparent,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Tags',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.path,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileTags.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No tags assigned to this file',
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              fileTags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tag.color.withAlpha(
                                          (0.2 * 255).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: tag.color.withAlpha(
                                            (0.3 * 255).round(),
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_offer,
                                            color: tag.color,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tag.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: tag.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () async {
                                              await tagsService
                                                  .removeTagFromFile(
                                                    file.path,
                                                    tag.id,
                                                  );
                                              setState(() {});
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                color: tag.color,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Add Tags',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            availableTags
                                .where((tag) => !fileTags.contains(tag))
                                .map(
                                  (tag) => InkWell(
                                    onTap: () async {
                                      await tagsService.addTagToFile(
                                        file.path,
                                        tag,
                                      );
                                      setState(() {});
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? const Color(0xFF3C4043)
                                                : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            color: tag.color,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            tag.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
