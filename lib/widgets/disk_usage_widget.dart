import 'package:flutter/material.dart';
import '../services/disk_service.dart';

class DiskUsageWidget extends StatefulWidget {
  final String path;
  
  const DiskUsageWidget({
    super.key,
    required this.path,
  });

  @override
  State<DiskUsageWidget> createState() => _DiskUsageWidgetState();
}

class _DiskUsageWidgetState extends State<DiskUsageWidget> {
  final DiskService _diskService = DiskService();
  DiskSpace? _diskSpace;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDiskInfo();
  }
  
  @override
  void didUpdateWidget(DiskUsageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) {
      _loadDiskInfo();
    }
  }

  Future<void> _loadDiskInfo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final diskSpace = await _diskService.getDiskSpaceInfo(widget.path);
      
      setState(() {
        _diskSpace = diskSpace;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF303030) : const Color(0xFFE8E8E8),
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.black54 : Colors.black12,
            ),
          ),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    
    if (_hasError || _diskSpace == null) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF303030) : const Color(0xFFE8E8E8),
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.black54 : Colors.black12,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load disk information',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _loadDiskInfo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF303030) : const Color(0xFFE8E8E8),
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.black54 : Colors.black12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Disk Usage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '${_diskSpace!.usagePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _getDiskSpaceColor(_diskSpace!.usagePercentage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _diskSpace!.usagePercentage / 100,
              backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getDiskSpaceColor(_diskSpace!.usagePercentage),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Free: ${_diskService.formatBytes(_diskSpace!.availableBytes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              Text(
                'Total: ${_diskService.formatBytes(_diskSpace!.totalBytes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getDiskSpaceColor(double percentage) {
    if (percentage >= 90) {
      return Colors.red;
    } else if (percentage >= 75) {
      return Colors.orange;
    } else if (percentage >= 60) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }
} 