class AppItem {
  final String name;
  final String path;
  final String icon;
  final String desktopFile;
  final bool isSystemApp;
  final bool isFlatpak;
  final bool isAppImage;
  final bool isDnfPackage;

  AppItem({
    required this.name,
    required this.path,
    required this.icon,
    required this.desktopFile,
    this.isSystemApp = false,
    this.isFlatpak = false,
    this.isAppImage = false,
    this.isDnfPackage = false,
  });

  // Create from JSON for storage
  factory AppItem.fromJson(Map<String, dynamic> json) {
    return AppItem(
      name: json['name'] as String,
      path: json['path'] as String,
      icon: json['icon'] as String,
      desktopFile: json['desktopFile'] as String,
      isSystemApp: json['isSystemApp'] as bool? ?? false,
      isFlatpak: json['isFlatpak'] as bool? ?? false,
      isAppImage: json['isAppImage'] as bool? ?? false,
      isDnfPackage: json['isDnfPackage'] as bool? ?? false,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'icon': icon,
      'desktopFile': desktopFile,
      'isSystemApp': isSystemApp,
      'isFlatpak': isFlatpak,
      'isAppImage': isAppImage,
      'isDnfPackage': isDnfPackage,
    };
  }
}
