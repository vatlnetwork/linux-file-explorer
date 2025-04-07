import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/icon_size_service.dart';
import 'file_item_widget.dart'; // Import for HoverBuilder

class GridItemWidget extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final Function(FileItem) onLongPress;
  final Function(FileItem, Offset position) onRightClick;
  final bool isSelected;

  const GridItemWidget({
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
    final iconSize = iconSizeService.gridIconSize;
    final uiScale = iconSizeService.gridUIScale;
    final titleSize = iconSizeService.gridTitleSize;
    final subtitleSize = iconSizeService.gridSubtitleSize;
    
    // Calculate padding that scales down less aggressively at small sizes
    final scaledPadding = 8.0 * (uiScale > 0.9 ? uiScale : 0.9);
    final scaledMargin = 6.0 * (uiScale > 0.9 ? uiScale : 0.9);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: HoverBuilder(
        builder: (context, isHovering) {
          return Card(
            margin: EdgeInsets.all(scaledMargin),
            elevation: 0,
            color: isSelected
                ? (isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50)
                : (isHovering 
                    ? (isDarkMode ? Color(0xFF2C2C2C) : Colors.grey.shade100)
                    : Colors.transparent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.0 * uiScale),
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
                onTap: onTap,
                onDoubleTap: onDoubleTap,
                onLongPress: () => onLongPress(item),
                child: Padding(
                  padding: EdgeInsets.all(scaledPadding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate minimum height for the icon container
                      final minContainerHeight = 24.0;
                      
                      // Determine if we need to fit text based on available space
                      // Use a more conservative threshold for small UI scales
                      final heightThreshold = 60.0 * (uiScale > 1.0 ? uiScale : 1.0);
                      final hasSpaceForText = constraints.maxHeight > heightThreshold;
                      final hasSpaceForSubtitle = constraints.maxHeight > (heightThreshold + 20.0);
                      
                      // Calculate specific heights based on available space
                      final iconHeight = hasSpaceForText 
                          ? constraints.maxHeight * 0.6
                          : constraints.maxHeight;
                      
                      return ClipRect(
                        child: Align(
                          alignment: Alignment.center,
                          heightFactor: 1.0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon container that takes most space
                              SizedBox(
                                height: iconHeight.clamp(minContainerHeight, double.infinity),
                                width: double.infinity,
                                child: Center(
                                  child: _buildItemIcon(iconSize),
                                ),
                              ),
                              
                              // Only show text if there's enough space
                              if (hasSpaceForText) ...[
                                SizedBox(height: 4.0 * uiScale.clamp(0.7, 1.0)),
                                Text(
                                  item.name,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: titleSize,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                
                                // Subtitle - only if we have even more space
                                if (hasSpaceForSubtitle) ...[
                                  SizedBox(height: 2.0 * uiScale.clamp(0.7, 1.0)),
                                  Text(
                                    item.type == FileItemType.directory ? 'Folder' : item.formattedSize,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: subtitleSize,
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemIcon(double size) {
    if (item.type == FileItemType.directory) {
      return Icon(Icons.folder, color: Colors.blue, size: size);
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
    
    return Icon(iconData, color: iconColor, size: size);
  }
} 