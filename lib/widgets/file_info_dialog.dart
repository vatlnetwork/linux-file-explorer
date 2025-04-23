import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import 'dart:io';
import 'dart:async';

class FileInfoDialog extends StatefulWidget {
  final FileItem item;

  const FileInfoDialog({
    super.key,
    required this.item,
  });

  @override
  State<FileInfoDialog> createState() => _FileInfoDialogState();
}

class _FileInfoDialogState extends State<FileInfoDialog> with SingleTickerProviderStateMixin {
  String? _ownerName;
  String? _groupName;
  String? _permissions;
  String? _fileType;
  String? _fileEncoding;
  String? _fileSizeOnDisk;
  bool _isLoading = true;
  late TabController _tabController;
  bool _isLocked = false;
  final Map<String, bool> _permissionStates = {
    'Read': true,
    'Write': true,
    'Execute': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFileInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFileInfo() async {
    try {
      // Get owner and group
      final ownerResult = await Process.run('stat', ['-c', '%U', widget.item.path]);
      final groupResult = await Process.run('stat', ['-c', '%G', widget.item.path]);
      final permissionsResult = await Process.run('stat', ['-c', '%A', widget.item.path]);
      
      // Get file type and encoding
      final fileTypeResult = await Process.run('file', ['-b', '--mime-type', widget.item.path]);
      final fileEncodingResult = await Process.run('file', ['-b', '--mime-encoding', widget.item.path]);
      
      // Get actual size on disk
      final sizeResult = await Process.run('du', ['-b', widget.item.path]);
      
      setState(() {
        _ownerName = ownerResult.exitCode == 0 ? ownerResult.stdout.toString().trim() : 'Unknown';
        _groupName = groupResult.exitCode == 0 ? groupResult.stdout.toString().trim() : 'Unknown';
        _permissions = permissionsResult.exitCode == 0 ? permissionsResult.stdout.toString().trim() : 'Unknown';
        _fileType = fileTypeResult.exitCode == 0 ? fileTypeResult.stdout.toString().trim() : 'Unknown';
        _fileEncoding = fileEncodingResult.exitCode == 0 ? fileEncodingResult.stdout.toString().trim() : 'Unknown';
        _fileSizeOnDisk = sizeResult.exitCode == 0 ? sizeResult.stdout.toString().trim() : 'Unknown';
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
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Row(
              children: [
                Icon(
                  widget.item.type == FileItemType.directory ? Icons.folder : Icons.insert_drive_file,
                  size: 48,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.dirname(widget.item.path),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'More Info'),
                Tab(text: 'Sharing & Permissions'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // General Tab
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(
                          context,
                          'General',
                          [
                            _buildInfoRow('Kind', _isLoading ? 'Loading...' : _fileType ?? 'Unknown'),
                            _buildInfoRow('Size', widget.item.formattedSize),
                            _buildInfoRow('Size on disk', _isLoading ? 'Loading...' : _fileSizeOnDisk ?? 'Unknown'),
                            _buildInfoRow('Created', widget.item.formattedCreationTime),
                            _buildInfoRow('Modified', widget.item.formattedModifiedTime),
                            _buildInfoRow('Owner', _isLoading ? 'Loading...' : _ownerName ?? 'Unknown'),
                            _buildInfoRow('Group', _isLoading ? 'Loading...' : _groupName ?? 'Unknown'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Lock checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _isLocked,
                              onChanged: (value) => setState(() => _isLocked = value ?? false),
                            ),
                            const Text('Locked'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // More Info Tab
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(
                          context,
                          'File Details',
                          [
                            _buildInfoRow('Full Path', widget.item.path),
                            _buildInfoRow('Extension', widget.item.fileExtension),
                            _buildInfoRow('Encoding', _isLoading ? 'Loading...' : _fileEncoding ?? 'Unknown'),
                            _buildInfoRow('Permissions', _isLoading ? 'Loading...' : _permissions ?? 'Unknown'),
                          ],
                        ),
                        
                        if (widget.item.type == FileItemType.directory) ...[
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            context,
                            'Directory Details',
                            [
                              _buildInfoRow('Items', 'Calculating...'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Sharing & Permissions Tab
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoSection(
                          context,
                          'Sharing & Permissions',
                          [
                            _buildInfoRow('Owner', _isLoading ? 'Loading...' : _ownerName ?? 'Unknown'),
                            _buildInfoRow('Group', _isLoading ? 'Loading...' : _groupName ?? 'Unknown'),
                            _buildInfoRow('Permissions', _isLoading ? 'Loading...' : _permissions ?? 'Unknown'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Permission checkboxes
                        _buildInfoSection(
                          context,
                          'Access',
                          [
                            _buildPermissionCheckbox('Read', true),
                            _buildPermissionCheckbox('Write', true),
                            _buildPermissionCheckbox('Execute', widget.item.type == FileItemType.directory),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 24),
            
            // Footer buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCheckbox(String label, bool defaultValue) {
    return Row(
      children: [
        Checkbox(
          value: _permissionStates[label] ?? defaultValue,
          onChanged: (value) async {
            if (value != null) {
              setState(() => _permissionStates[label] = value);
              try {
                final permission = _calculatePermission();
                await Process.run('chmod', [permission, widget.item.path]);
              } catch (e) {
                // Revert on error
                setState(() => _permissionStates[label] = !value);
              }
            }
          },
        ),
        Text(label),
      ],
    );
  }

  String _calculatePermission() {
    int permission = 0;
    if (_permissionStates['Read'] ?? false) permission += 4;
    if (_permissionStates['Write'] ?? false) permission += 2;
    if (_permissionStates['Execute'] ?? false) permission += 1;
    return '$permission$permission$permission';
  }
} 