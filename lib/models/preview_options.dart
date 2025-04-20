import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents preference options for the preview panel
class PreviewOptions {
  // Common metadata options
  bool showTags;
  bool showCreated;
  bool showModified;
  bool showSize;
  bool showWhereFrom;
  bool showQuickActions;
  
  // Image specific options
  bool showDimensions;
  bool showExifData;
  bool showCameraModel;
  bool showExposureInfo;
  
  // Document specific options
  bool showAuthor;
  bool showPageCount;
  
  // Media specific options
  bool showDuration;
  bool showCodecs;
  bool showBitrate;
  
  PreviewOptions({
    this.showTags = true,
    this.showCreated = true,
    this.showModified = true,
    this.showSize = true,
    this.showWhereFrom = false,
    this.showQuickActions = true,
    
    this.showDimensions = true,
    this.showExifData = false,
    this.showCameraModel = false,
    this.showExposureInfo = false,
    
    this.showAuthor = true,
    this.showPageCount = true,
    
    this.showDuration = true,
    this.showCodecs = false,
    this.showBitrate = false,
  });
  
  /// Creates a copy of this PreviewOptions with specified properties replaced
  PreviewOptions copyWith({
    bool? showTags,
    bool? showCreated,
    bool? showModified,
    bool? showSize,
    bool? showWhereFrom,
    bool? showQuickActions,
    bool? showDimensions,
    bool? showExifData,
    bool? showCameraModel,
    bool? showExposureInfo,
    bool? showAuthor,
    bool? showPageCount,
    bool? showDuration,
    bool? showCodecs,
    bool? showBitrate,
  }) {
    return PreviewOptions(
      showTags: showTags ?? this.showTags,
      showCreated: showCreated ?? this.showCreated,
      showModified: showModified ?? this.showModified,
      showSize: showSize ?? this.showSize,
      showWhereFrom: showWhereFrom ?? this.showWhereFrom,
      showQuickActions: showQuickActions ?? this.showQuickActions,
      
      showDimensions: showDimensions ?? this.showDimensions,
      showExifData: showExifData ?? this.showExifData,
      showCameraModel: showCameraModel ?? this.showCameraModel,
      showExposureInfo: showExposureInfo ?? this.showExposureInfo,
      
      showAuthor: showAuthor ?? this.showAuthor,
      showPageCount: showPageCount ?? this.showPageCount,
      
      showDuration: showDuration ?? this.showDuration,
      showCodecs: showCodecs ?? this.showCodecs,
      showBitrate: showBitrate ?? this.showBitrate,
    );
  }
  
  /// Convert to a Map for storage
  Map<String, dynamic> toMap() {
    return {
      'showTags': showTags,
      'showCreated': showCreated,
      'showModified': showModified,
      'showSize': showSize,
      'showWhereFrom': showWhereFrom,
      'showQuickActions': showQuickActions,
      
      'showDimensions': showDimensions,
      'showExifData': showExifData,
      'showCameraModel': showCameraModel,
      'showExposureInfo': showExposureInfo,
      
      'showAuthor': showAuthor,
      'showPageCount': showPageCount,
      
      'showDuration': showDuration,
      'showCodecs': showCodecs,
      'showBitrate': showBitrate,
    };
  }
  
  /// Convert to a JSON string
  String toJson() {
    return jsonEncode(toMap());
  }
  
  /// Create from a Map (from storage)
  factory PreviewOptions.fromMap(Map<String, dynamic> map) {
    return PreviewOptions(
      showTags: map['showTags'] ?? true,
      showCreated: map['showCreated'] ?? true,
      showModified: map['showModified'] ?? true,
      showSize: map['showSize'] ?? true,
      showWhereFrom: map['showWhereFrom'] ?? false,
      showQuickActions: map['showQuickActions'] ?? true,
      
      showDimensions: map['showDimensions'] ?? true,
      showExifData: map['showExifData'] ?? false,
      showCameraModel: map['showCameraModel'] ?? false,
      showExposureInfo: map['showExposureInfo'] ?? false,
      
      showAuthor: map['showAuthor'] ?? true,
      showPageCount: map['showPageCount'] ?? true,
      
      showDuration: map['showDuration'] ?? true,
      showCodecs: map['showCodecs'] ?? false,
      showBitrate: map['showBitrate'] ?? false,
    );
  }
  
  /// Create from a JSON string
  factory PreviewOptions.fromJson(String json) {
    if (json.isEmpty) {
      return PreviewOptions();
    }
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PreviewOptions.fromMap(map);
    } catch (e) {
      // If JSON is invalid, return default options
      return PreviewOptions();
    }
  }
}

/// Manages preview options for different file types
class PreviewOptionsManager {
  static const String _imageOptionsKey = 'preview_options_image';
  static const String _documentOptionsKey = 'preview_options_document';
  static const String _mediaOptionsKey = 'preview_options_media';
  static const String _defaultOptionsKey = 'preview_options_default';
  
  // Initialize with default values to prevent LateInitializationError
  PreviewOptions _imageOptions = PreviewOptions(
    showDimensions: true,
    showExifData: false,
    showCameraModel: true,
  );
  
  PreviewOptions _documentOptions = PreviewOptions(
    showAuthor: true,
    showPageCount: true,
  );
  
  PreviewOptions _mediaOptions = PreviewOptions(
    showDuration: true,
    showCodecs: false,
    showBitrate: false,
  );
  
  PreviewOptions _defaultOptions = PreviewOptions();
  bool _loaded = false;
  
  PreviewOptions get imageOptions => _imageOptions;
  PreviewOptions get documentOptions => _documentOptions;
  PreviewOptions get mediaOptions => _mediaOptions;
  PreviewOptions get defaultOptions => _defaultOptions;
  
  Future<void> loadOptions() async {
    if (_loaded) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load image options
    final imageOptionsJson = prefs.getString(_imageOptionsKey);
    if (imageOptionsJson != null) {
      _imageOptions = PreviewOptions.fromJson(imageOptionsJson);
    }
    
    // Load document options
    final documentOptionsJson = prefs.getString(_documentOptionsKey);
    if (documentOptionsJson != null) {
      _documentOptions = PreviewOptions.fromJson(documentOptionsJson);
    }
    
    // Load media options
    final mediaOptionsJson = prefs.getString(_mediaOptionsKey);
    if (mediaOptionsJson != null) {
      _mediaOptions = PreviewOptions.fromJson(mediaOptionsJson);
    }
    
    // Load default options
    final defaultOptionsJson = prefs.getString(_defaultOptionsKey);
    if (defaultOptionsJson != null) {
      _defaultOptions = PreviewOptions.fromJson(defaultOptionsJson);
    }
    
    _loaded = true;
  }
  
  Future<void> saveImageOptions(PreviewOptions options) async {
    _imageOptions = options;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageOptionsKey, options.toJson());
  }
  
  Future<void> saveDocumentOptions(PreviewOptions options) async {
    _documentOptions = options;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_documentOptionsKey, options.toJson());
  }
  
  Future<void> saveMediaOptions(PreviewOptions options) async {
    _mediaOptions = options;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mediaOptionsKey, options.toJson());
  }
  
  Future<void> saveDefaultOptions(PreviewOptions options) async {
    _defaultOptions = options;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultOptionsKey, options.toJson());
  }
  
  /// Gets the appropriate options for a given file extension
  PreviewOptions getOptionsForFileExtension(String extension) {
    final ext = extension.toLowerCase();
    
    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return _imageOptions;
    }
    
    // Document files
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(ext)) {
      return _documentOptions;
    }
    
    // Media files
    if (['.mp4', '.avi', '.mov', '.mkv', '.webm', '.mp3', '.wav', '.aac', '.flac'].contains(ext)) {
      return _mediaOptions;
    }
    
    // Default
    return _defaultOptions;
  }
} 