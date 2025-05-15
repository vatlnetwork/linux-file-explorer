import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../models/preview_options.dart';

class PreviewOptionsDialog extends StatefulWidget {
  final PreviewOptions options;
  final FileItem fileItem;
  
  const PreviewOptionsDialog({
    super.key, 
    required this.options,
    required this.fileItem,
  });

  @override
  State<PreviewOptionsDialog> createState() => _PreviewOptionsDialogState();
}

class _PreviewOptionsDialogState extends State<PreviewOptionsDialog> {
  late PreviewOptions _currentOptions;
  
  @override
  void initState() {
    super.initState();
    _currentOptions = widget.options;
  }
  
  @override
  Widget build(BuildContext context) {
    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(
      widget.fileItem.fileExtension.toLowerCase()
    );
    
    final isDocument = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'].contains(
      widget.fileItem.fileExtension.toLowerCase()
    );
    
    final isMedia = ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.mp3', '.wav', '.aac', '.flac'].contains(
      widget.fileItem.fileExtension.toLowerCase()
    );

    final isFolder = widget.fileItem.type == FileItemType.directory;
    
    String title;
    if (isFolder) {
      title = 'Folder Preview Options';
    } else if (isImage) {
      title = 'Image Preview Options';
    } else if (isDocument) {
      title = 'Document Preview Options';
    } else if (isMedia) {
      title = 'Media Preview Options';
    } else {
      title = 'Preview Options';
    }
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            _buildSwitchTile(
              'Tags',
              _currentOptions.showTags,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showTags: value)),
            ),
            _buildSwitchTile(
              'Created Date',
              _currentOptions.showCreated,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showCreated: value)),
            ),
            _buildSwitchTile(
              'Modified Date',
              _currentOptions.showModified,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showModified: value)),
            ),
            _buildSwitchTile(
              'Size',
              _currentOptions.showSize,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showSize: value)),
            ),
            _buildSwitchTile(
              'Where From (Download Source)',
              _currentOptions.showWhereFrom,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showWhereFrom: value)),
            ),
            _buildSwitchTile(
              'Quick Actions',
              _currentOptions.showQuickActions,
              (value) => setState(() => _currentOptions = _currentOptions.copyWith(showQuickActions: value)),
            ),
            
            if (isFolder) ...[
              const SizedBox(height: 8),
              const Text(
                'Folder Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildSwitchTile(
                'Show Contents',
                _currentOptions.showFolderContents,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showFolderContents: value)),
              ),
              _buildSwitchTile(
                'Show Folder Size',
                _currentOptions.showFolderSize,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showFolderSize: value)),
              ),
              _buildSwitchTile(
                'Show Item Count',
                _currentOptions.showItemCount,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showItemCount: value)),
              ),
              _buildSwitchTile(
                'Show Hidden Items',
                _currentOptions.showHiddenItems,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showHiddenItems: value)),
              ),
            ],
            
            if (isImage) ...[
              const SizedBox(height: 8),
              const Text(
                'Image Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildSwitchTile(
                'Dimensions',
                _currentOptions.showDimensions,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showDimensions: value)),
              ),
              _buildSwitchTile(
                'EXIF Data',
                _currentOptions.showExifData,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showExifData: value)),
              ),
              _buildSwitchTile(
                'Camera Model',
                _currentOptions.showCameraModel,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showCameraModel: value)),
              ),
              _buildSwitchTile(
                'Exposure Information',
                _currentOptions.showExposureInfo,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showExposureInfo: value)),
              ),
            ],
            
            if (isDocument) ...[
              const SizedBox(height: 8),
              const Text(
                'Document Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildSwitchTile(
                'Author',
                _currentOptions.showAuthor,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showAuthor: value)),
              ),
              _buildSwitchTile(
                'Page Count',
                _currentOptions.showPageCount,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showPageCount: value)),
              ),
            ],
            
            if (isMedia) ...[
              const SizedBox(height: 8),
              const Text(
                'Media Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildSwitchTile(
                'Duration',
                _currentOptions.showDuration,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showDuration: value)),
              ),
              _buildSwitchTile(
                'Codecs',
                _currentOptions.showCodecs,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showCodecs: value)),
              ),
              _buildSwitchTile(
                'Bitrate',
                _currentOptions.showBitrate,
                (value) => setState(() => _currentOptions = _currentOptions.copyWith(showBitrate: value)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _currentOptions);
          },
          child: Text(
            'Save',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSwitchTile(String title, bool value, void Function(bool) onChanged) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      visualDensity: VisualDensity.compact,
      controlAffinity: ListTileControlAffinity.trailing,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: isDarkMode ? Colors.grey.shade300 : null,
      activeTrackColor: isDarkMode ? Colors.grey.shade700 : null,
      inactiveThumbColor: isDarkMode ? Colors.grey.shade400 : null,
      inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : null,
    );
  }
} 