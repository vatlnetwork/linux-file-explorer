import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/disk_service.dart';
import '../services/usb_drive_service.dart';
import '../services/theme_service.dart';

class DiskManagerScreen extends StatefulWidget {
  static const String routeName = '/disk-manager';

  const DiskManagerScreen({super.key});

  @override
  State<DiskManagerScreen> createState() => _DiskManagerScreenState();
}

class _DiskManagerScreenState extends State<DiskManagerScreen> {
  final DiskService _diskService = DiskService();
  final UsbDriveService _usbDriveService = UsbDriveService();
  List<DiskSpace> _mountedDisks = [];
  List<UsbDrive> _usbDrives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiskInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDiskInfo() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get all mounted disks
      final mountedDisks = await _diskService.getAllMountedDisks();
      final usbDrives = await _usbDriveService.getMountedUsbDrives();

      if (!mounted) return;

      setState(() {
        _mountedDisks = mountedDisks;
        _usbDrives = usbDrives;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF202124) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF2D2E30) : Colors.white,
        title: const Text('Disk Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiskInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Disks',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDarkMode ? Colors.white : Colors.grey[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._buildSystemDisks(isDarkMode),
                    const SizedBox(height: 32),
                    if (_usbDrives.isNotEmpty) ...[
                      Text(
                        'USB Drives',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._buildUsbDrives(isDarkMode),
                    ],
                  ],
                ),
              ),
    );
  }

  List<Widget> _buildSystemDisks(bool isDarkMode) {
    return _mountedDisks.map((disk) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isDarkMode ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? const Color(0xFF3C4043) : Colors.grey[300]!,
            width: isDarkMode ? 1 : 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2E30) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage,
                      color:
                          isDarkMode
                              ? const Color(0xFF8AB4F8)
                              : const Color(0xFF1A73E8),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        disk.mountPoint,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'File System: ${disk.fileSystem}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${_diskService.formatBytes(disk.totalBytes)} | '
                  'Used: ${_diskService.formatBytes(disk.usedBytes)} | '
                  'Available: ${_diskService.formatBytes(disk.availableBytes)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: disk.usagePercentage / 100,
                  backgroundColor:
                      isDarkMode
                          ? const Color(0xFF3C4043)
                          : const Color(0xFFF1F3F4),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getUsageColor(disk.usagePercentage, isDarkMode),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${disk.usagePercentage.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                if (disk.mountPoint != '/') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Analyze'),
                        onPressed: () => _showDiskAnalysis(disk),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.cleaning_services_outlined),
                        label: const Text('Clean'),
                        onPressed: () => _showCleanupOptions(disk),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildUsbDrives(bool isDarkMode) {
    return _usbDrives.map((drive) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isDarkMode ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? const Color(0xFF3C4043) : Colors.grey[300]!,
            width: isDarkMode ? 1 : 1.5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2E30) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.usb,
                      color:
                          isDarkMode
                              ? const Color(0xFF81C995)
                              : const Color(0xFF34A853),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        drive.label.isNotEmpty ? drive.label : drive.deviceName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.eject),
                      onPressed: () => _ejectDrive(drive),
                      tooltip: 'Eject',
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Mount Point: ${drive.mountPoint}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Device: ${drive.deviceName}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${_usbDriveService.formatBytes(drive.totalBytes)}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getUsageColor(double percentage, bool isDarkMode) {
    if (percentage >= 90) {
      return isDarkMode ? Colors.red[300]! : Colors.red[700]!;
    } else if (percentage >= 75) {
      return isDarkMode ? Colors.orange[300]! : Colors.orange[700]!;
    } else if (percentage >= 60) {
      return isDarkMode ? Colors.yellow[300]! : Colors.yellow[700]!;
    }
    return isDarkMode ? Colors.green[300]! : Colors.green[700]!;
  }

  Future<void> _ejectDrive(UsbDrive drive) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eject Drive'),
            content: Text(
              'Are you sure you want to eject "${drive.label.isNotEmpty ? drive.label : drive.deviceName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eject'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await _usbDriveService.ejectDrive(drive.deviceName);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Drive ejected successfully' : 'Failed to eject drive',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _loadDiskInfo();
      }
    }
  }

  Future<void> _showDiskAnalysis(DiskSpace disk) async {
    final largestFiles = await _diskService.getLargestFiles(disk.mountPoint);
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Disk Analysis'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: largestFiles.length,
                itemBuilder: (context, index) {
                  final file = largestFiles[index];
                  return ListTile(
                    title: Text(file.name),
                    subtitle: Text(file.sizeFormatted),
                    leading: const Icon(Icons.insert_drive_file),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _showCleanupOptions(DiskSpace disk) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cleanup Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Temporary Files'),
                  subtitle: const Text('Clean system temporary files'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _cleanupTemporaryFiles(disk);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Package Cache'),
                  subtitle: const Text('Clean package manager cache'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _cleanupPackageCache(disk);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Trash'),
                  subtitle: const Text('Empty trash'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _emptyTrash(disk);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _cleanupTemporaryFiles(DiskSpace disk) async {
    final success = await _diskService.cleanupTemporaryFiles(disk.mountPoint);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Temporary files cleaned successfully'
              : 'Failed to clean temporary files',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadDiskInfo();
    }
  }

  Future<void> _cleanupPackageCache(DiskSpace disk) async {
    final success = await _diskService.cleanupPackageCache(disk.mountPoint);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Package cache cleaned successfully'
              : 'Failed to clean package cache',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadDiskInfo();
    }
  }

  Future<void> _emptyTrash(DiskSpace disk) async {
    final success = await _diskService.emptyTrash(disk.mountPoint);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Trash emptied successfully' : 'Failed to empty trash',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _loadDiskInfo();
    }
  }
}
