import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';

final _logger = Logger('UsbDriveService');

class UsbDrive {
  final String mountPoint;
  final String deviceName;
  final String label;
  final int totalBytes;
  final String driveType;

  UsbDrive({
    required this.mountPoint,
    required this.deviceName,
    this.label = '',
    required this.totalBytes,
    required this.driveType,
  });
}

class UsbDriveService {
  /// Returns a list of mounted USB drives
  Future<List<UsbDrive>> getMountedUsbDrives() async {
    List<UsbDrive> usbDrives = [];
    
    try {
      // First, get all mounted drives
      final ProcessResult result = await Process.run('lsblk', ['-o', 'NAME,MOUNTPOINT,SIZE,TYPE,LABEL,RM,TRAN', '-J']);
      if (result.exitCode != 0) {
        _logger.warning('lsblk command failed: ${result.stderr}');
        return [];
      }
      
      // Parse the JSON output
      final String output = result.stdout.toString();
      final data = await LinuxParser.parseBlockDevices(output);
      
      for (var device in data) {
        // Only include USB removable drives that are mounted
        if (device.isUsb && device.mountPoint.isNotEmpty) {
          usbDrives.add(UsbDrive(
            mountPoint: device.mountPoint,
            deviceName: device.name,
            label: device.label,
            totalBytes: device.sizeInBytes,
            driveType: device.type,
          ));
        }
      }
      
      return usbDrives;
    } catch (e) {
      _logger.warning('Error getting USB drives: $e');
      return [];
    }
  }
  
  /// Unmounts a drive by its mount point
  Future<bool> unmountDrive(String mountPoint) async {
    try {
      _logger.info('Attempting to unmount drive at $mountPoint');
      
      // Use umount command to unmount the drive
      final ProcessResult result = await Process.run('umount', [mountPoint]);
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to unmount drive: ${result.stderr}');
        return false;
      }
      
      _logger.info('Successfully unmounted drive at $mountPoint');
      return true;
    } catch (e) {
      _logger.warning('Error unmounting drive: $e');
      return false;
    }
  }
  
  /// Safely ejects a drive (unmount and power off) by its device name
  Future<bool> ejectDrive(String deviceName) async {
    try {
      _logger.info('Attempting to eject drive $deviceName');
      
      // First, make sure to extract the main device name if it's a partition
      String mainDeviceName = LinuxParser.extractMainDeviceName(deviceName);
      
      // Use udisksctl to eject the drive
      final ProcessResult result = await Process.run(
        'udisksctl', ['power-off', '-b', '/dev/$mainDeviceName']
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to eject drive: ${result.stderr}');
        return false;
      }
      
      _logger.info('Successfully ejected drive $deviceName');
      return true;
    } catch (e) {
      _logger.warning('Error ejecting drive: $e');
      return false;
    }
  }
  
  /// Helper to format bytes to human-readable string
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Helper class to parse output from Linux commands
class LinuxParser {
  static Future<List<BlockDevice>> parseBlockDevices(String jsonOutput) async {
    List<BlockDevice> devices = [];
    try {
      // Parse JSON from lsblk
      Map<String, dynamic> parsed = {};
      try {
        parsed = json.decode(jsonOutput);
      } catch (e) {
        _logger.warning('Failed to parse JSON: $e');
        return [];
      }
      
      List<dynamic> blockDevices = parsed['blockdevices'] ?? [];
      
      for (var device in blockDevices) {
        if (device['type'] == 'disk' || device['type'] == 'part') {
          // Check if it's a removable USB drive using the 'rm' and 'tran' fields
          // 'rm' == 1 means removable, 'tran' == 'usb' means USB transport
          bool isRemovable = device['rm'] == true || device['rm'] == 1;
          bool isUsbTransport = device['tran'] == 'usb';
          bool isUsb = isRemovable && (isUsbTransport || await _checkUsbSysfs(device['name']));
          
          if (isUsb) {
            devices.add(BlockDevice(
              name: device['name'],
              mountPoint: device['mountpoint'] ?? '',
              sizeInBytes: _parseSize(device['size'] ?? '0'),
              type: device['type'] ?? '',
              label: device['label'] ?? '',
              isUsb: true,
            ));
          }
          
          // Process children (partitions)
          if (device['children'] != null) {
            for (var child in device['children']) {
              if (child['mountpoint'] != null && isUsb) {
                devices.add(BlockDevice(
                  name: child['name'],
                  mountPoint: child['mountpoint'] ?? '',
                  sizeInBytes: _parseSize(child['size'] ?? '0'),
                  type: child['type'] ?? '',
                  label: child['label'] ?? '',
                  isUsb: true,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      _logger.warning('Error parsing block devices: $e');
    }
    
    return devices;
  }
  
  static String extractMainDeviceName(String deviceName) {
    // Extract the base device name (e.g., 'sdb' from 'sdb1')
    RegExp regex = RegExp(r'^([a-zA-Z]+)');
    final match = regex.firstMatch(deviceName);
    return match?.group(1) ?? deviceName;
  }
  
  static int _parseSize(String sizeStr) {
    try {
      // Handle different size formats (like 8G, 512M)
      final RegExp sizeRegex = RegExp(r'(\d+(\.\d+)?)([KMGT])?');
      final match = sizeRegex.firstMatch(sizeStr);
      
      if (match != null) {
        double size = double.parse(match.group(1)!);
        String? unit = match.group(3);
        
        switch (unit) {
          case 'K':
            return (size * 1024).round();
          case 'M':
            return (size * 1024 * 1024).round();
          case 'G':
            return (size * 1024 * 1024 * 1024).round();
          case 'T':
            return (size * 1024 * 1024 * 1024 * 1024).round();
          default:
            return size.round();
        }
      }
      
      return 0;
    } catch (e) {
      _logger.warning('Error parsing size: $e');
      return 0;
    }
  }
  
  // Additional check using sysfs to determine if a device is a USB drive
  static Future<bool> _checkUsbSysfs(String deviceName) async {
    try {
      // Extract main device name (e.g., 'sdb' from 'sdb1')
      String mainDeviceName = extractMainDeviceName(deviceName);
      
      // Check if it's a removable device
      final removableResult = await Process.run(
        'sh', 
        ['-c', 'cat /sys/block/$mainDeviceName/removable']
      );
      bool isRemovable = removableResult.stdout.toString().trim() == '1';
      
      if (!isRemovable) {
        return false;
      }
      
      // Check if it's connected via USB by looking at the device path
      final devicePathResult = await Process.run(
        'sh',
        ['-c', 'readlink -f /sys/block/$mainDeviceName/device'],
      );
      
      String devicePath = devicePathResult.stdout.toString().trim();
      
      // If the device path contains "usb", it's most likely a USB drive
      return devicePath.contains('usb');
    } catch (e) {
      _logger.fine('Error checking if $deviceName is USB: $e');
      return false;
    }
  }
}

class BlockDevice {
  final String name;
  final String mountPoint;
  final int sizeInBytes;
  final String type;
  final String label;
  final bool isUsb;
  
  BlockDevice({
    required this.name,
    required this.mountPoint,
    required this.sizeInBytes,
    required this.type,
    required this.label,
    required this.isUsb,
  });
} 