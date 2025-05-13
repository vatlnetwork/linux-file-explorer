import 'package:flutter/material.dart';

class BookmarkSidebar extends StatelessWidget {
  final List<String> bookmarks;
  final Function(String) onBookmarkSelected;
  final Function(String) onBookmarkRemoved;
  final bool isVisible;

  const BookmarkSidebar({
    super.key,
    required this.bookmarks,
    required this.onBookmarkSelected,
    required this.onBookmarkRemoved,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return Container(
      width: 250.0,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 48.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark),
                const SizedBox(width: 8.0),
                Text(
                  'Bookmarks',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(
                    bookmark.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    bookmark,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => onBookmarkSelected(bookmark),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onBookmarkRemoved(bookmark),
                    tooltip: 'Remove bookmark',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 