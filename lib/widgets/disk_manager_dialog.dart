import 'package:flutter/material.dart';
import '../services/disk_service.dart';
import 'dart:developer' as developer;

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
  String _selectedAction = '';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
        backgroundColor: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
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
      _selectedAction = action;
    });

    try {
      switch (action) {
        case 'cleanup':
          // TODO: Implement cleanup functionality
          await Future.delayed(const Duration(seconds: 2)); // Simulated delay
          break;
        case 'analyze':
          // TODO: Implement analysis functionality
          await Future.delayed(const Duration(seconds: 2)); // Simulated delay
          break;
        case 'health':
          // TODO: Implement health check functionality
          await Future.delayed(const Duration(seconds: 2)); // Simulated delay
          break;
        case 'backup':
          // TODO: Implement backup functionality
          await Future.delayed(const Duration(seconds: 2)); // Simulated delay
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
          _selectedAction = '';
        });
      }
    }
  }
} 