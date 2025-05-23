import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../services/disk_service.dart';

class DiskManagerDialog extends StatefulWidget {
  final String? path;
  final DiskSpace? diskSpace;

  const DiskManagerDialog({super.key, this.path, this.diskSpace});

  @override
  State<DiskManagerDialog> createState() => _DiskManagerDialogState();
}

class _DiskManagerDialogState extends State<DiskManagerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  List<DiskInfo> _disks = [];
  bool _isLoading = true;
  DiskInfo? _selectedDisk;
  bool _showActions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _loadDisks();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDisks() async {
    try {
      // Run df command to get disk information
      final result = await Process.run('df', ['-h']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        // Skip header line
        lines.removeAt(0);

        setState(() {
          _disks =
              lines
                  .where((line) => line.trim().isNotEmpty)
                  .map((line) {
                    final parts =
                        line
                            .split(RegExp(r'\s+'))
                            .where((s) => s.isNotEmpty)
                            .toList();
                    if (parts.length >= 6) {
                      return DiskInfo(
                        filesystem: parts[0],
                        size: parts[1],
                        used: parts[2],
                        available: parts[3],
                        usePercentage: parts[4],
                        mountPoint: parts.sublist(5).join(' '),
                      );
                    }
                    return null;
                  })
                  .where((disk) => disk != null)
                  .cast<DiskInfo>()
                  .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading disk information: $e')),
        );
      }
    }
  }

  Future<void> _handleDiskAction(String action, DiskInfo disk) async {
    setState(() => _isLoading = true);

    try {
      switch (action) {
        case 'analyze':
          await _analyzeDisk(disk);
          break;
        case 'cleanup':
          await _cleanupDisk(disk);
          break;
        case 'health':
          await _checkDiskHealth(disk);
          break;
        case 'backup':
          await _backupDisk(disk);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeDisk(DiskInfo disk) async {
    // Get the largest files in the disk
    final result = await Process.run('du', [
      '-ah',
      disk.mountPoint,
      '|',
      'sort',
      '-rh',
      '|',
      'head',
      '-n',
      '10',
    ]);

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Disk Analysis: ${disk.mountPoint}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Largest Files/Directories:'),
                  const SizedBox(height: 8),
                  ...result.stdout
                      .toString()
                      .split('\n')
                      .where((line) => line.trim().isNotEmpty)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(line),
                        ),
                      ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _cleanupDisk(DiskInfo disk) async {
    // Find and list temporary files
    final tempFiles = await Process.run('find', [
      disk.mountPoint,
      '-type',
      'f',
      '(',
      '-name',
      '*.tmp',
      '-o',
      '-name',
      '*.temp',
      '-o',
      '-name',
      '*~',
      ')',
    ]);

    final files =
        tempFiles.stdout
            .toString()
            .split('\n')
            .where((f) => f.trim().isNotEmpty)
            .toList();

    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Clean Temporary Files'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Found ${files.length} temporary files. Delete them?'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    width: 400,
                    child: ListView.builder(
                      itemCount: files.length,
                      itemBuilder:
                          (context, index) => Text(
                            p.basename(files[index]),
                            style: TextStyle(fontSize: 12),
                          ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        for (final file in files) {
          try {
            await File(file).delete();
          } catch (e) {
            print('Error deleting $file: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${files.length} temporary files'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkDiskHealth(DiskInfo disk) async {
    try {
      // Check if smartctl is available
      final smartctlCheck = await Process.run('which', ['smartctl']);
      if (smartctlCheck.exitCode != 0) {
        throw Exception('smartctl not found. Please install smartmontools.');
      }

      // Get the device path
      final devicePath = disk.filesystem;

      // Run SMART test
      final result = await Process.run('smartctl', ['-H', devicePath]);

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Disk Health Check'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Results for ${disk.mountPoint}:'),
                    const SizedBox(height: 8),
                    Text(result.stdout.toString()),
                    if (result.stderr.toString().isNotEmpty)
                      Text(
                        result.stderr.toString(),
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _backupDisk(DiskInfo disk) async {
    final downloadsPath = '${Platform.environment['HOME']}/Downloads';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath =
        '$downloadsPath/backup_${p.basename(disk.mountPoint)}_$timestamp';

    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Backup ${disk.mountPoint}'),
              content: Text(
                'This will create a backup in:\n$backupPath\n\nContinue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Backup'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text('Creating Backup'),
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Creating backup...'),
                  ],
                ),
              ),
        );

        try {
          // Create backup using tar
          await Process.run('tar', [
            '-czf',
            '$backupPath.tar.gz',
            '-C',
            p.dirname(disk.mountPoint),
            p.basename(disk.mountPoint),
          ]);

          // Close progress dialog
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backup created at $backupPath.tar.gz'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Close progress dialog on error
          if (mounted) {
            Navigator.pop(context);
          }
          rethrow;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor:
                  isDarkMode ? const Color(0xFF2D2E30) : Colors.white,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 500,
                ),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Dialog header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? const Color(0xFF3C3C3C)
                                    : Colors.grey[100],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage,
                                size: 24,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Disk Manager',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    Navigator.of(context).pop();
                                  });
                                },
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                        ),
                        // Dialog content
                        Flexible(
                          child:
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: _disks.length,
                                    itemBuilder: (context, index) {
                                      final disk = _disks[index];
                                      final usePercentage =
                                          double.tryParse(
                                            disk.usePercentage.replaceAll(
                                              '%',
                                              '',
                                            ),
                                          ) ??
                                          0.0;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 8,
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedDisk = disk;
                                              _showActions = true;
                                            });
                                          },
                                          child: ListTile(
                                            title: Text(
                                              disk.mountPoint,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                LinearProgressIndicator(
                                                  value: usePercentage / 100,
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        usePercentage > 90
                                                            ? Colors.red
                                                            : usePercentage > 75
                                                            ? Colors.orange
                                                            : Colors.green,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Used: ${disk.used} of ${disk.size} (${disk.usePercentage} used, ${disk.available} available)',
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode
                                                            ? Colors.grey[300]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  'Filesystem: ${disk.filesystem}',
                                                  style: TextStyle(
                                                    color:
                                                        isDarkMode
                                                            ? Colors.grey[300]
                                                            : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            leading: Icon(
                                              disk.mountPoint == '/'
                                                  ? Icons.storage
                                                  : Icons.folder,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                        // Dialog footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? const Color(0xFF3C3C3C)
                                    : Colors.grey[100],
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  _controller.reverse().then((_) {
                                    Navigator.of(context).pop();
                                  });
                                },
                                child: const Text('Close'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _loadDisks,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Action panel
                    if (_showActions && _selectedDisk != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => setState(() => _showActions = false),
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.all(32),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? const Color(0xFF2D2E30)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Manage ${_selectedDisk!.mountPoint}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.analytics,
                                          label: 'Analyze',
                                          color: Colors.blue,
                                          onPressed:
                                              () => _handleDiskAction(
                                                'analyze',
                                                _selectedDisk!,
                                              ),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.cleaning_services,
                                          label: 'Clean Up',
                                          color: Colors.green,
                                          onPressed:
                                              () => _handleDiskAction(
                                                'cleanup',
                                                _selectedDisk!,
                                              ),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.health_and_safety,
                                          label: 'Check Health',
                                          color: Colors.orange,
                                          onPressed:
                                              () => _handleDiskAction(
                                                'health',
                                                _selectedDisk!,
                                              ),
                                        ),
                                        _buildActionButton(
                                          icon: Icons.backup,
                                          label: 'Backup',
                                          color: Colors.purple,
                                          onPressed:
                                              () => _handleDiskAction(
                                                'backup',
                                                _selectedDisk!,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class DiskInfo {
  final String filesystem;
  final String size;
  final String used;
  final String available;
  final String usePercentage;
  final String mountPoint;

  DiskInfo({
    required this.filesystem,
    required this.size,
    required this.used,
    required this.available,
    required this.usePercentage,
    required this.mountPoint,
  });
}

class BackupSelectionDialog extends StatefulWidget {
  final String path;

  const BackupSelectionDialog({super.key, required this.path});

  @override
  State<BackupSelectionDialog> createState() => _BackupSelectionDialogState();
}

class _BackupSelectionDialogState extends State<BackupSelectionDialog> {
  final List<String> _selectedItems = [];
  bool _isLoading = true;
  List<FileSystemEntity> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final directory = Directory(widget.path);
      final items = await directory.list().toList();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Items to Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedItems.contains(item.path);
                    final isDirectory = item is Directory;

                    return ListTile(
                      leading: Icon(
                        isDirectory ? Icons.folder : Icons.insert_drive_file,
                        color: isDirectory ? Colors.blue : Colors.grey,
                      ),
                      title: Text(
                        item.path.split('/').last,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedItems.add(item.path);
                            } else {
                              _selectedItems.remove(item.path);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _selectedItems.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_selectedItems),
                  child: const Text('Backup Selected'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
