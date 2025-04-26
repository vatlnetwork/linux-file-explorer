import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../services/file_system_service.dart';

class GetInfoDialog extends StatefulWidget {
  final FileItem item;
  
  const GetInfoDialog({
    super.key,
    required this.item,
  });

  @override
  State<GetInfoDialog> createState() => _GetInfoDialogState();
}

class _GetInfoDialogState extends State<GetInfoDialog> with SingleTickerProviderStateMixin {
  late FileSystemEntity _entity;
  bool _isLoading = true;
  String? _error;
  Map<String, String> _info = {};
  late TabController _tabController;
  
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
      _entity = widget.item.type == FileItemType.directory
          ? Directory(widget.item.path)
          : File(widget.item.path);
      
      final stat = await _entity.stat();
      final fileSystemService = FileSystemService();
      
      final owner = await fileSystemService.getFileOwner(widget.item.path);
      final group = await fileSystemService.getFileGroup(widget.item.path);
      
      if (!mounted) return;
      
      setState(() {
        _info = {
          'Name': widget.item.name,
          'Kind': widget.item.type == FileItemType.directory ? 'Folder' : '${widget.item.fileExtension.toUpperCase().replaceFirst('.', '')} File',
          'Size': widget.item.formattedSize,
          'Created': widget.item.formattedCreationTime,
          'Modified': widget.item.formattedModifiedTime,
          'Path': widget.item.path,
          'Permissions': stat.modeString().substring(1),
          'Owner': owner,
          'Group': group,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading file info: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 600,
        height: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.item.type == FileItemType.directory
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        size: 24,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'General'),
                      Tab(text: 'More Info'),
                      Tab(text: 'Sharing & Permissions'),
                    ],
                    labelColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    indicatorColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // General Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          Center(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          )
                        else ...[
                          // Preview section
                          if (widget.item.type == FileItemType.file) ...[
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getIconForFile(widget.item),
                                    size: 64,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          _buildInfoRow('Kind', _getKindDescription(widget.item)),
                          _buildInfoRow('Size', widget.item.formattedSize),
                          _buildInfoRow('Where', p.dirname(widget.item.path)),
                          _buildInfoRow('Created', widget.item.formattedCreationTime),
                          _buildInfoRow('Modified', widget.item.formattedModifiedTime),
                          if (widget.item.whereFrom != null)
                            _buildInfoRow('Where from', widget.item.whereFrom!),
                        ],
                      ],
                    ),
                  ),
                  
                  // More Info Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          Center(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          )
                        else ...[
                          _buildInfoRow('File extension', widget.item.fileExtension),
                          _buildInfoRow('File name', p.basename(widget.item.path)),
                          _buildInfoRow('Full path', widget.item.path),
                        ],
                      ],
                    ),
                  ),
                  
                  // Sharing & Permissions Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_error != null)
                          Center(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          )
                        else ...[
                          _buildInfoRow('Owner', _info['Owner'] ?? 'Unknown'),
                          _buildInfoRow('Group', _info['Group'] ?? 'Unknown'),
                          _buildInfoRow('Access', _getAccessString(_info['Permissions'] ?? '')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getKindDescription(FileItem item) {
    if (item.type == FileItemType.directory) {
      return 'Folder';
    }
    
    final ext = item.fileExtension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return 'Image';
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return 'Video';
    } else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      return 'Audio';
    } else if (['.pdf'].contains(ext)) {
      return 'PDF Document';
    } else if (['.doc', '.docx'].contains(ext)) {
      return 'Word Document';
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return 'Excel Spreadsheet';
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return 'PowerPoint Presentation';
    } else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return 'Text Document';
    } else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      return 'Compressed Archive';
    } else {
      return '${ext.toUpperCase().replaceAll('.', '')} File';
    }
  }
  
  IconData _getIconForFile(FileItem item) {
    final ext = item.fileExtension.toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) {
      return Icons.image;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.webm'].contains(ext)) {
      return Icons.video_library;
    } else if (['.mp3', '.wav', '.aac', '.flac', '.ogg'].contains(ext)) {
      return Icons.audiotrack;
    } else if (['.pdf'].contains(ext)) {
      return Icons.picture_as_pdf;
    } else if (['.doc', '.docx'].contains(ext)) {
      return Icons.description;
    } else if (['.xls', '.xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['.txt', '.md', '.json', '.yaml', '.yml', '.xml', '.html', '.css', '.js'].contains(ext)) {
      return Icons.text_snippet;
    } else if (['.zip', '.rar', '.tar', '.gz', '.7z'].contains(ext)) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }
  
  String _getAccessString(String permissions) {
    if (permissions.isEmpty) return 'Unknown';
    
    final read = permissions.contains('r');
    final write = permissions.contains('w');
    
    if (read && write) return 'Read & Write';
    if (read) return 'Read only';
    if (write) return 'Write only';
    return 'No access';
  }
} 