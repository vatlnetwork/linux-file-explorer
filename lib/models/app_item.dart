class AppItem {
  final String name;
  final String path;
  final String icon;
  final String desktopFile;

  AppItem({
    required this.name,
    required this.path,
    required this.icon,
    required this.desktopFile,
  });

  // Create from JSON for storage
  factory AppItem.fromJson(Map<String, dynamic> json) {
    return AppItem(
      name: json['name'],
      path: json['path'],
      icon: json['icon'],
      desktopFile: json['desktopFile'],
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'icon': icon,
      'desktopFile': desktopFile,
    };
  }
} 