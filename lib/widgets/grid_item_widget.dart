import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/icon_size_service.dart';
import 'file_item_widget.dart'; // Import for HoverBuilder

/// A widget to display a file or folder in a grid layout
class GridItemWidget extends StatelessWidget {
  final FileItem item;
  final Function(FileItem, bool) onTap;
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
                onTap: () {
                  // Check if Ctrl key is pressed
                  final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
                  onTap(item, isCtrlPressed);
                },
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
                      final iconHeight = constraints.maxHeight > 0 
                          ? (hasSpaceForText 
                              ? constraints.maxHeight * 0.55 // Reduced from 0.6 to reserve more space for text
                              : constraints.maxHeight)
                          : minContainerHeight;
                      
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
                                height: constraints.maxHeight > 0 
                                    ? iconHeight.clamp(minContainerHeight, constraints.maxHeight * 0.55) 
                                    : minContainerHeight,
                                width: double.infinity,
                                child: Center(
                                  child: _buildItemIcon(iconSize),
                                ),
                              ),
                              
                              // Only show text if there's enough space
                              if (hasSpaceForText) ...[
                                SizedBox(height: uiScale > 0 ? (8.0 * uiScale).clamp(4.0, 12.0) : 4.0), // Added null safety
                                Flexible(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth,
                                    ),
                                    child: Text(
                                      item.name,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: uiScale > 0 
                                            ? (titleSize * (1.0 / uiScale).clamp(0.5, 1.0)).clamp(10.0, 14.0)
                                            : 12.0, // Default value if calculation fails
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Subtitle - only if we have even more space
                                if (hasSpaceForSubtitle) ...[
                                  SizedBox(height: uiScale > 0 ? (4.0 * uiScale).clamp(2.0, 6.0) : 2.0), // Added null safety
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      child: Text(
                                        item.type == FileItemType.directory ? 'Folder' : item.formattedSize,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: uiScale > 0 
                                              ? (subtitleSize * (1.0 / uiScale).clamp(0.5, 1.0)).clamp(8.0, 11.0)
                                              : 9.0, // Default value if calculation fails
                                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                        ),
                                      ),
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
    // Cap the maximum icon size to prevent layout issues
    double safeSize = size.clamp(0, 80.0);
    
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