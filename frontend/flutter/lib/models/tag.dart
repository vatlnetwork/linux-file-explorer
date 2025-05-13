import 'package:flutter/material.dart';
import 'dart:convert';

class Tag {
  final String id;
  final String name;
  final Color color;
  
  /// Create a tag with a name and optional color
  const Tag({
    required this.id,
    required this.name,
    this.color = Colors.blue,
  });

  /// Create a tag with a randomly generated ID
  factory Tag.create({
    required String name,
    Color color = Colors.blue,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return Tag(
      id: id,
      name: name,
      color: color,
    );
  }

  /// Convert a Tag to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
    };
  }

  /// Convert a Tag to a JSON string
  String toJson() {
    return json.encode(toMap());
  }

  /// Create a Tag from a Map
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
    );
  }

  /// Create a Tag from a JSON string
  factory Tag.fromJson(String source) {
    return Tag.fromMap(json.decode(source));
  }

  /// Create a copy of this Tag with new values
  Tag copyWith({
    String? id,
    String? name,
    Color? color,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Tag &&
      other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Common predefined tags
class CommonTags {
  static const Tag work = Tag(
    id: 'work',
    name: 'Work',
    color: Colors.blue,
  );
  
  static const Tag personal = Tag(
    id: 'personal',
    name: 'Personal',
    color: Colors.green,
  );
  
  static const Tag important = Tag(
    id: 'important',
    name: 'Important',
    color: Colors.red,
  );
  
  static const Tag vacation = Tag(
    id: 'vacation',
    name: 'Vacation',
    color: Colors.orange,
  );
  
  static const Tag documents = Tag(
    id: 'documents',
    name: 'Documents',
    color: Colors.purple,
  );
  
  static const Tag photos = Tag(
    id: 'photos',
    name: 'Photos',
    color: Colors.cyan,
  );
  
  static const Tag videos = Tag(
    id: 'videos',
    name: 'Videos',
    color: Colors.amber,
  );
  
  static const Tag music = Tag(
    id: 'music',
    name: 'Music',
    color: Colors.pink,
  );
  
  /// Get a list of all common tags
  static List<Tag> getAll() {
    return [
      work,
      personal,
      important,
      vacation,
      documents,
      photos,
      videos,
      music,
    ];
  }
} 