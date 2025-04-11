import 'package:flutter/material.dart';
import '../services/disk_service.dart';

class LargestFilesPopup extends StatefulWidget {
  final String path;
  final Size size;
  final Function onClose;

  const LargestFilesPopup({
    Key? key,
    required this.path,
    required this.size,
    required this.onClose,
  }) : super(key: key);

  @override
  State<LargestFilesPopup> createState() => _LargestFilesPopupState();
}

class _LargestFilesPopupState extends State<LargestFilesPopup> {
  final DiskService _diskService = DiskService();
  List<FileSize> _largestFiles = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadLargestFiles();
  }
  
  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadLargestFiles() async {
    if (!_isMounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final files = await _diskService.getLargestFiles(widget.path);
      
      if (!_isMounted) return;
      
      setState(() {
        _largestFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!_isMounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF252525) : const Color(0xFFF0F0F0);
    final foregroundColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Largest Files',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: foregroundColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: foregroundColor),
                    onPressed: () => widget.onClose(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildContent(isDarkMode, foregroundColor, subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode, Color foregroundColor, Color subtitleColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              'Scanning files...',
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 16),
            Text(
              'Failed to load largest files',
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
            TextButton(
              onPressed: _loadLargestFiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_largestFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: subtitleColor, size: 32),
            const SizedBox(height: 16),
            Text(
              'No files found',
              style: TextStyle(color: subtitleColor, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: _largestFiles.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 1,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
      ),
      itemBuilder: (context, index) {
        final file = _largestFiles[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            file.name,
            style: TextStyle(
              fontSize: 13,
              color: foregroundColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            file.path,
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              file.sizeFormatted,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
} 