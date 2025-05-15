import 'package:flutter/material.dart';
import '../services/disk_service.dart';
import 'dart:developer' as developer;
import 'dart:io';

class DiskManagerDialog extends StatefulWidget {
  final String path;
  final DiskSpace diskSpace;

  const DiskManagerDialog({
    super.key,
    required this.path,
    required this.diskSpace,
  });

  @override
  State<DiskManagerDialog> createState() => _DiskManagerDialogState();
}

class _DiskManagerDialogState extends State<DiskManagerDialog> {
  final DiskService _diskService = DiskService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  size: 24,
                  color: isDarkMode ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                ),
                const SizedBox(width: 12),
                Text(
                  'Disk Manager',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDiskInfoSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiskInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disk Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Total Space', _diskService.formatBytes(widget.diskSpace.totalBytes)),
          const SizedBox(height: 8),
          _buildInfoRow('Used Space', _diskService.formatBytes(widget.diskSpace.usedBytes)),
          const SizedBox(height: 8),
          _buildInfoRow('Free Space', _diskService.formatBytes(widget.diskSpace.availableBytes)),
          const SizedBox(height: 8),
          _buildInfoRow('Usage', '${widget.diskSpace.usagePercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.cleaning_services,
          label: 'Clean Up',
          onPressed: () => _handleAction('cleanup'),
          color: Colors.blue,
        ),
        _buildActionButton(
          icon: Icons.analytics,
          label: 'Analyze',
          onPressed: () => _handleAction('analyze'),
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.security,
          label: 'Check Health',
          onPressed: () => _handleAction('health'),
          color: Colors.orange,
        ),
        _buildActionButton(
          icon: Icons.backup,
          label: 'Backup',
          onPressed: () => _handleAction('backup'),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? color.withAlpha(51) : color.withAlpha(26),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    setState(() {
      _isLoading = true;
    });

    try {
      switch (action) {
        case 'cleanup':
          // Find and delete temporary files
          final tempFiles = await _diskService.getLargestFiles(widget.path, limit: 50);
          int cleanedSize = 0;
          for (var file in tempFiles) {
            if (file.name.endsWith('.tmp') || file.name.endsWith('.temp')) {
              try {
                await File(file.path).delete();
                cleanedSize += file.sizeBytes ?? 0;
              } catch (e) {
                developer.log('Error deleting temp file: $e');
              }
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cleaned up ${_diskService.formatBytes(cleanedSize)} of temporary files'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case 'analyze':
          // Analyze disk usage and show largest files
          final largestFiles = await _diskService.getLargestFiles(widget.path, limit: 10);
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Disk Analysis'),
                content: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top 10 Largest Files:'),
                      const SizedBox(height: 8),
                      ...largestFiles.map((file) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                file.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(file.sizeFormatted),
                          ],
                        ),
                      )),
                    ],
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
          break;

        case 'health':
          // Check disk health using smartctl if available
          try {
            // First get the device path from the mount point
            final mountResult = await Process.run('df', ['--output=source', widget.path]);
            if (mountResult.exitCode != 0) {
              throw Exception('Failed to get device information');
            }

            // Parse the output to get the device path
            final devicePath = mountResult.stdout.toString().split('\n')[1].trim();
            
            // Run smartctl on the device
            final result = await Process.run('smartctl', ['-H', devicePath]);
            
            if (mounted) {
              if (result.exitCode == 0) {
                // Parse the smartctl output to get the health status
                final output = result.stdout.toString();
                final isHealthy = output.toLowerCase().contains('passed');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isHealthy 
                      ? 'Disk health check passed'
                      : 'Disk health check failed: ${result.stdout}'),
                    backgroundColor: isHealthy ? Colors.green : Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Disk health check failed: ${result.stderr}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            developer.log('Error checking disk health: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Disk health check failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          break;

        case 'backup':
          // Show backup selection dialog
          final selectedItems = await showDialog<List<String>>(
            context: context,
            builder: (context) => BackupSelectionDialog(
              path: widget.path,
              diskService: _diskService,
            ),
          );

          if (selectedItems != null && selectedItems.isNotEmpty) {
            // Create backup directory in Downloads
            final downloadsPath = '${Platform.environment['HOME']}/Downloads';
            final backupDir = '$downloadsPath/backup_${DateTime.now().millisecondsSinceEpoch}';
            
            try {
              await Directory(backupDir).create();
              int backedUpSize = 0;

              for (final itemPath in selectedItems) {
                final item = FileSystemEntity.typeSync(itemPath) == FileSystemEntityType.directory
                    ? Directory(itemPath)
                    : File(itemPath);
                final itemName = itemPath.split('/').last;
                final targetPath = '$backupDir/$itemName';

                if (item is File) {
                  await File(itemPath).copy(targetPath);
                  backedUpSize += await File(itemPath).length();
                } else if (item is Directory) {
                  await _copyDirectory(itemPath, targetPath);
                  // Calculate directory size
                  final sizeResult = await Process.run('du', ['-sb', itemPath]);
                  if (sizeResult.exitCode == 0) {
                    final sizeStr = sizeResult.stdout.toString().split('\t')[0];
                    backedUpSize += int.tryParse(sizeStr) ?? 0;
                  }
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Backed up ${_diskService.formatBytes(backedUpSize)} to $backupDir'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Backup failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
          break;
      }
    } catch (e) {
      developer.log('Error performing disk action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing $action: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);
    
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final targetEntity = '${targetDir.path}/${entity.path.split('/').last}';
      
      if (entity is File) {
        await File(entity.path).copy(targetEntity);
      } else if (entity is Directory) {
        await _copyDirectory(entity.path, targetEntity);
      }
    }
  }
}

class BackupSelectionDialog extends StatefulWidget {
  final String path;
  final DiskService diskService;

  const BackupSelectionDialog({
    super.key,
    required this.path,
    required this.diskService,
  });

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  onPressed: _selectedItems.isEmpty
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