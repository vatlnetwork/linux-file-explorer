import 'package:flutter/material.dart';
import '../services/usb_drive_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class MountedUsbDrivesWidget extends StatefulWidget {
  final Function(String) onNavigate;
  
  const MountedUsbDrivesWidget({
    super.key,
    required this.onNavigate,
  });

  @override
  State<MountedUsbDrivesWidget> createState() => _MountedUsbDrivesWidgetState();
}

class _MountedUsbDrivesWidgetState extends State<MountedUsbDrivesWidget> {
  final UsbDriveService _usbDriveService = UsbDriveService();
  List<UsbDrive> _usbDrives = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  // Timer for periodic refresh
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsbDrives();
    
    // Set up a periodic refresh timer to detect when USB drives are inserted or removed
    // Increased from 10 seconds to 30 seconds to reduce frequent checks
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUsbDrives();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUsbDrives() async {
    // Don't set loading state to true for periodic refreshes
    // Only set it to true for the initial load or explicit refreshes
    bool initialLoad = _isLoading;
    
    if (initialLoad) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    
    try {
      final usbDrives = await _usbDriveService.getMountedUsbDrives();
      
      // Only update state if the drives list has actually changed or this is the initial load
      bool drivesChanged = _drivesListChanged(_usbDrives, usbDrives);
      
      if (drivesChanged || initialLoad) {
        setState(() {
          _usbDrives = usbDrives;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  // Helper method to check if the drives list has changed
  bool _drivesListChanged(List<UsbDrive> oldList, List<UsbDrive> newList) {
    if (oldList.length != newList.length) {
      return true;
    }
    
    // Compare each drive by mountPoint (which should be a unique identifier)
    for (int i = 0; i < oldList.length; i++) {
      if (oldList[i].mountPoint != newList[i].mountPoint) {
        return true;
      }
    }
    
    return false;
  }

  // This function will handle the refresh button click without showing loading indicators
  Future<void> _refreshUsbDrives() async {
    try {
      final usbDrives = await _usbDriveService.getMountedUsbDrives();
      
      bool drivesChanged = _drivesListChanged(_usbDrives, usbDrives);
      
      if (drivesChanged) {
        setState(() {
          _usbDrives = usbDrives;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // If no drives are found and we're not loading, don't show the widget
    if (_usbDrives.isEmpty && !_isLoading && !_hasError) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF252525) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
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
                Icons.usb,
                size: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'USB Drives',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 16,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                  onPressed: _refreshUsbDrives,
                  tooltip: 'Refresh',
                  splashRadius: 16,
                )
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Failed to load USB drives',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            _buildUsbDrivesList(context),
        ],
      ),
    );
  }
  
  Widget _buildUsbDrivesList(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _usbDrives.map((drive) {
        final driveLabel = drive.label.isNotEmpty 
            ? drive.label 
            : '${drive.deviceName} (${_usbDriveService.formatBytes(drive.totalBytes)})';
            
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: InkWell(
            onTap: () => widget.onNavigate(drive.mountPoint),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withValues(alpha: 0.3) 
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.amber.shade900 : Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.usb_rounded,
                          size: 20,
                          color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driveLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              drive.mountPoint,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _usbDriveService.formatBytes(drive.totalBytes),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (BuildContext buttonContext) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            context: buttonContext,
                            icon: Icons.eject,
                            label: 'Unmount',
                            onPressed: () => _unmountDrive(buttonContext, drive),
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            context: buttonContext,
                            icon: Icons.usb_off,
                            label: 'Eject',
                            onPressed: () => _ejectDrive(buttonContext, drive),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _unmountDrive(BuildContext context, UsbDrive drive) async {
    // Capture ScaffoldMessenger before any async operation
    final messenger = ScaffoldMessenger.of(context);
    
    // Show confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Unmount Drive'),
        content: Text('Are you sure you want to unmount ${drive.label.isNotEmpty ? drive.label : drive.deviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Unmount'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _usbDriveService.unmountDrive(drive.mountPoint);
      
      if (!mounted) return;
      
      if (success) {
        // Show success notification
        NotificationService.showNotification(
          messenger,
          message: '${drive.label.isNotEmpty ? drive.label : drive.deviceName} unmounted successfully',
          type: NotificationType.success,
        );
        
        // Refresh the list
        await _loadUsbDrives();
      } else {
        // Show error notification
        NotificationService.showNotification(
          messenger,
          message: 'Failed to unmount drive. Make sure it\'s not in use.',
          type: NotificationType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationService.showNotification(
        messenger,
        message: 'Error: ${e.toString()}',
        type: NotificationType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _ejectDrive(BuildContext context, UsbDrive drive) async {
    // Capture ScaffoldMessenger before any async operation
    final messenger = ScaffoldMessenger.of(context);
    
    // Show confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eject Drive'),
        content: Text('Are you sure you want to eject ${drive.label.isNotEmpty ? drive.label : drive.deviceName}?\n\nThis will unmount the drive and power it off.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eject'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _usbDriveService.ejectDrive(drive.deviceName);
      
      if (!mounted) return;
      
      if (success) {
        // Show success notification
        NotificationService.showNotification(
          messenger,
          message: '${drive.label.isNotEmpty ? drive.label : drive.deviceName} ejected successfully',
          type: NotificationType.success,
        );
        
        // Refresh the list
        await _loadUsbDrives();
      } else {
        // Show error notification
        NotificationService.showNotification(
          messenger,
          message: 'Failed to eject drive. Make sure it\'s not in use.',
          type: NotificationType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error notification
      NotificationService.showNotification(
        messenger,
        message: 'Error: ${e.toString()}',
        type: NotificationType.error,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
} 