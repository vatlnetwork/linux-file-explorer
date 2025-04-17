import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/icon_size_service.dart';
import 'file_item_widget.dart'; // Import for HoverBuilder

/// A widget to display a file or folder in gallery view with large preview
class GalleryItemWidget extends StatelessWidget {
  final FileItem item;
  final Function(FileItem, bool) onTap;
  final VoidCallback onDoubleTap;
  final Function(FileItem) onLongPress;
  final Function(FileItem, Offset position) onRightClick;
  final bool isSelected;

  const GalleryItemWidget({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDoubleTap,
    required this.onLongPress,
    required this.onRightClick,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconSizeService = Provider.of<IconSizeService>(context);
    final uiScale = iconSizeService.gridUIScale;
    final titleSize = iconSizeService.gridTitleSize;
    final subtitleSize = iconSizeService.gridSubtitleSize;
    
    // Calculate padding that scales down less aggressively at small sizes
    final scaledPadding = 10.0 * (uiScale > 0.9 ? uiScale : 0.9);
    final scaledMargin = 8.0 * (uiScale > 0.9 ? uiScale : 0.9);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HoverBuilder(
        builder: (context, isHovering) {
          return Card(
            margin: EdgeInsets.all(scaledMargin),
            elevation: isHovering ? 3 : 1,
            color: isSelected
                ? (isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50)
                : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0 * uiScale),
              side: BorderSide(
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300)
                    : Colors.transparent,
                width: isSelected ? 1.5 * uiScale : 0,
              ),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onSecondaryTapUp: (details) {
                onRightClick(item, details.globalPosition);
              },
              child: InkWell(
                onTap: () {
                  // Check if Ctrl key is pressed
                  final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
                  onTap(item, isCtrlPressed);
                },
                onDoubleTap: onDoubleTap,
                onLongPress: () => onLongPress(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview area (larger portion)
                    Expanded(
                      flex: 4,
                      child: _buildPreviewArea(context),
                    ),
                    
                    // Info area (smaller portion)
                    Container(
                      padding: EdgeInsets.all(scaledPadding),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black26 : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8.0 * uiScale),
                          bottomRight: Radius.circular(8.0 * uiScale),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: titleSize,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2.0 * uiScale.clamp(0.7, 1.0)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.type == FileItemType.directory
                                    ? 'Folder'
                                    : item.formattedSize,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                item.formattedModifiedTime,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: subtitleSize,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          // Optional: Add quick action buttons for the item
                          if (_shouldShowQuickActions() && isHovering)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: _buildQuickActions(context),
                            ),
                        ],
                      ),
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

  Widget _buildPreviewArea(BuildContext context) {
    if (item.type == FileItemType.directory) {
      return _buildDirectoryPreview(context);
    }

    // Image files
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(item.fileExtension.toLowerCase())) {
      return _buildImagePreview(context);
    }
    
    // Text files - show text sample
    if (['.txt', '.md', '.html', '.css', '.json', '.yaml', '.yml'].contains(item.fileExtension.toLowerCase())) {
      return _buildTextPreview(context);
    }
    
    // PDF files
    if (['.pdf'].contains(item.fileExtension.toLowerCase())) {
      return _buildPdfPreview(context);
    }
    
    // Video files
    if (['.mp4', '.avi', '.mov', '.mkv'].contains(item.fileExtension.toLowerCase())) {
      return _buildVideoPreview(context);
    }
    
    // Default file icon
    return _buildDefaultPreview(context);
  }

  Widget _buildDirectoryPreview(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.amber,
          ),
          const SizedBox(height: 8),
          Text(
            'Directory',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.file(
          File(item.path),
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null) {
              return Center(child: CircularProgressIndicator());
            }
            return child;
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Icon(
        Icons.description,
        size: 64,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildPdfPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Icon(
        Icons.picture_as_pdf,
        size: 64,
        color: Colors.red,
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Icon(
        Icons.movie,
        size: 64,
        color: Colors.red,
      ),
    );
  }

  Widget _buildDefaultPreview(BuildContext context) {
    IconData iconData;
    Color iconColor;
    
    switch (item.fileExtension.toLowerCase()) {
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.flac':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
      case '.csv':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case '.ppt':
      case '.pptx':
        iconData = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case '.zip':
      case '.rar':
      case '.tar':
      case '.gz':
        iconData = Icons.archive;
        iconColor = Colors.brown;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.blueGrey;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Icon(
          iconData,
          size: 64,
          color: iconColor,
        ),
      ),
    );
  }
  
  bool _shouldShowQuickActions() {
    // Determine if we should show quick actions for this file type
    if (item.type == FileItemType.directory) {
      return true;
    }
    
    final ext = item.fileExtension.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.pdf', 
            '.mp4', '.mov', '.mp3', '.wav'].contains(ext);
  }
  
  Widget _buildQuickActions(BuildContext context) {
    final actions = <Widget>[];
    
    // Add common actions
    actions.add(
      Icon(Icons.visibility, size: 18, color: Colors.blue),
    );
    
    // Add image-specific actions
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(item.fileExtension.toLowerCase())) {
      actions.add(
        Icon(Icons.edit, size: 18, color: Colors.blue),
      );
      actions.add(
        Icon(Icons.rotate_right, size: 18, color: Colors.blue),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }
} 