import 'package:flutter/material.dart';
import '../services/disk_service.dart';
import 'largest_files_popup.dart';
import 'dart:developer' as developer;

class DiskUsageWidget extends StatefulWidget {
  final String path;

  const DiskUsageWidget({super.key, required this.path});

  @override
  State<DiskUsageWidget> createState() => _DiskUsageWidgetState();
}

class _DiskUsageWidgetState extends State<DiskUsageWidget> {
  final DiskService _diskService = DiskService();
  DiskSpace? _diskSpace;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showLargestFilesPopup = false;
  final GlobalKey _widgetKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _loadDiskInfo();
  }

  @override
  void dispose() {
    _isMounted = false;
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(DiskUsageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      _loadDiskInfo();
    }
  }

  Future<void> _loadDiskInfo() async {
    if (!_isMounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final diskSpace = await _diskService.getDiskSpaceInfo(widget.path);

      if (!_isMounted) return;

      setState(() {
        _diskSpace = diskSpace;
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

  void _toggleLargestFilesPopup() {
    if (_showLargestFilesPopup) {
      _removeOverlay();
      setState(() {
        _showLargestFilesPopup = false;
      });
    } else {
      setState(() {
        _showLargestFilesPopup = true;
      });
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showLargestFilesPopup || _widgetKey.currentContext == null) return;

      try {
        final RenderBox renderBox =
            _widgetKey.currentContext!.findRenderObject() as RenderBox;
        final Size widgetSize = renderBox.size;
        final Offset position = renderBox.localToGlobal(Offset.zero);

        final screenSize = MediaQuery.of(context).size;
        // Reduced dimensions for a more compact popup
        const popupWidth = 400.0;
        const popupHeight = 500.0;

        // Determine if there's enough space to the right
        // If not, show it on the left
        double left;
        if (position.dx + widgetSize.width + popupWidth > screenSize.width) {
          // Not enough space to the right, show on the left
          left = position.dx - popupWidth;
          if (left < 0) left = 0; // Ensure it's not off-screen
        } else {
          // Show on the right
          left = position.dx + widgetSize.width;
        }

        // Calculate top position, ensuring the popup fits in the screen
        double top = position.dy;
        if (top + popupHeight > screenSize.height) {
          top = screenSize.height - popupHeight;
          if (top < 0) top = 0;
        }

        _overlayEntry = OverlayEntry(
          builder:
              (context) => Positioned(
                left: left,
                top: top,
                child: LargestFilesPopup(
                  path: widget.path,
                  size: Size(popupWidth, popupHeight),
                  onClose: _toggleLargestFilesPopup,
                ),
              ),
        );

        // Make sure context is still valid before inserting overlay
        if (context.mounted) {
          Overlay.of(context).insert(_overlayEntry!);
        }
      } catch (e) {
        developer.log('Error showing overlay: $e');
        // Reset state if overlay creation fails
        setState(() {
          _showLargestFilesPopup = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? const Color(0xFF8AB4F8)
                      : const Color(0xFF1A73E8),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_hasError || _diskSpace == null) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Unable to load disk information',
                  style: TextStyle(
                    color:
                        isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadDiskInfo,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor:
                        isDarkMode
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleLargestFilesPopup,
      child: Card(
        key: _widgetKey,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDarkMode ? const Color(0xFF3C4043) : const Color(0xFFEEEEEE),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage,
                    size: 18,
                    color:
                        isDarkMode
                            ? const Color(0xFF8AB4F8)
                            : const Color(0xFF1A73E8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disk Usage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 18,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                    ),
                    onPressed: _toggleLargestFilesPopup,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Show Largest Files',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_diskService.formatBytes(_diskSpace!.usedBytes)} used',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                  Text(
                    '${_diskService.formatBytes(_diskSpace!.availableBytes)} free',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${_diskSpace!.usagePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white60 : Colors.black45,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _diskSpace!.usagePercentage / 100,
                    backgroundColor:
                        isDarkMode
                            ? const Color(0xFF3C4043)
                            : const Color(0xFFF1F3F4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForPercentage(
                        _diskSpace!.usagePercentage,
                        isDarkMode,
                      ),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage, bool isDarkMode) {
    if (percentage >= 90) {
      return isDarkMode
          ? const Color(0xFFE67C73)
          : const Color(0xFFD93025); // Red
    } else if (percentage >= 75) {
      return isDarkMode
          ? const Color(0xFFF9AB00)
          : const Color(0xFFEA8600); // Orange
    } else if (percentage >= 60) {
      return isDarkMode
          ? const Color(0xFFFDD663)
          : const Color(0xFFFBBC04); // Amber
    } else {
      return isDarkMode
          ? const Color(0xFF81C995)
          : const Color(0xFF188038); // Green
    }
  }
}
