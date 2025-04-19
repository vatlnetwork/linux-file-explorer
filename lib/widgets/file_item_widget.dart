import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/icon_size_service.dart';

/// A widget to display a file or folder in a list
class FileItemWidget extends StatelessWidget {
  final FileItem item;
  final Function(FileItem, bool) onTap;
  final VoidCallback onDoubleTap;
  final Function(FileItem) onLongPress;
  final Function(FileItem, Offset position) onRightClick;
  final bool isSelected;

  const FileItemWidget({
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
    final iconSize = iconSizeService.listIconSize;
    final uiScale = iconSizeService.listUIScale;
    final titleSize = iconSizeService.listTitleSize;
    final subtitleSize = iconSizeService.listSubtitleSize;
    
    // Calculate padding that scales down less aggressively at small sizes
    final scaledPadding = 8.0 * (uiScale > 0.9 ? uiScale : 0.9);
    final scaledMargin = 4.0 * (uiScale > 0.9 ? uiScale : 0.9);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HoverBuilder(
        builder: (context, isHovering) {
          return Card(
            margin: EdgeInsets.symmetric(
              vertical: scaledMargin,
              horizontal: scaledMargin * 2,
            ),
            elevation: 0,
            color: isSelected
                ? (isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50)
                : (isHovering 
                    ? (isDarkMode ? Color(0xFF2C2C2C) : Colors.grey.shade100)
                    : Colors.transparent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0 * uiScale),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final hasSpaceForSubtitle = constraints.maxHeight > (30.0 * uiScale);
                    
                    return ClipRect(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: scaledPadding,
                          vertical: scaledPadding / 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon with fixed width but scaled size
                            Container(
                              width: iconSize * 2.0,
                              alignment: Alignment.center,
                              child: _buildItemIcon(iconSize),
                            ),
                            SizedBox(width: 16.0 * uiScale.clamp(0.7, 1.0)),
                            
                            // Text content
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  if (hasSpaceForSubtitle) ...[
                                    SizedBox(height: 2.0 * uiScale.clamp(0.7, 1.0)),
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
                                  ],
                                ],
                              ),
                            ),
                            
                            // Right padding for consistent spacing
                            SizedBox(width: 8.0 * uiScale.clamp(0.7, 1.0)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemIcon(double size) {
    // Cap the maximum icon size to prevent layout issues
    double safeSize = size.clamp(0, 42.0); // Slightly smaller limit than grid view
    
    if (item.type == FileItemType.directory) {
      return Icon(Icons.folder, color: Colors.blue, size: safeSize);
    }

    // Determine icon based on file extension
    IconData iconData;
    Color iconColor;
    
    switch (item.fileExtension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case '.mp3':
      case '.wav':
      case '.ogg':
      case '.flac':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
        break;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.mkv':
        iconData = Icons.movie;
        iconColor = Colors.red;
        break;
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case '.doc':
      case '.docx':
      case '.txt':
      case '.rtf':
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
    
    return Icon(iconData, color: iconColor, size: safeSize);
  }
}

// Helper widget to detect hover
class HoverBuilder extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  
  const HoverBuilder({
    super.key, 
    required this.builder,
  });
  
  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovering = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: widget.builder(context, _isHovering),
    );
  }
} 