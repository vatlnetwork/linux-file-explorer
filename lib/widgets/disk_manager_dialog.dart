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
          // Create a backup directory and copy files
          final backupDir = '${widget.path}/backup_${DateTime.now().millisecondsSinceEpoch}';
          try {
            await Directory(backupDir).create();
            final files = await _diskService.getLargestFiles(widget.path);
            int backedUpSize = 0;
            for (var file in files) {
              try {
                await File(file.path).copy('$backupDir/${file.name}');
                backedUpSize += file.sizeBytes ?? 0;
              } catch (e) {
                developer.log('Error backing up file: $e');
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
} 