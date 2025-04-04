import '../models/file_item.dart';

class BookmarkItem {
  final String path;
  final String name;
  final DateTime createdAt;

  BookmarkItem({
    required this.path,
    required this.name,
    required this.createdAt,
  });

  // Create a bookmark from a FileItem
  factory BookmarkItem.fromFileItem(FileItem item) {
    return BookmarkItem(
      path: item.path,
      name: item.name,
      createdAt: DateTime.now(),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON 
  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      path: json['path'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 