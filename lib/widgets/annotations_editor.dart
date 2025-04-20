import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../services/notification_service.dart';
import 'package:logging/logging.dart' as logging;

class AnnotationsEditor extends StatefulWidget {
  final FileItem fileItem;

  const AnnotationsEditor({
    super.key,
    required this.fileItem,
  });

  @override
  State<AnnotationsEditor> createState() => _AnnotationsEditorState();
}

class _AnnotationsEditorState extends State<AnnotationsEditor> {
  final _logger = logging.Logger('AnnotationsEditor');
  bool _isLoading = true;
  bool _isSaving = false;
  final List<PDFAnnotation> _annotations = [];
  int _currentPage = 1;
  int _totalPages = 1;
  AnnotationType _currentAnnotationType = AnnotationType.highlight;
  Color _currentColor = Colors.yellow.withAlpha(128);
  
  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real implementation, this would load the PDF document
      // and extract existing annotations
      
      // Simulating loading delay
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _totalPages = 5; // Mock 5 pages for demo
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to load document: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _saveAnnotations() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // In a real implementation, this would save the annotations
      // back to the PDF file or create a new annotated PDF
      
      // Simulating saving delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate new filename for the annotated document
      final originalName = widget.fileItem.name;
      final extension = p.extension(originalName);
      final baseName = originalName.substring(0, originalName.length - extension.length);
      final directory = p.dirname(widget.fileItem.path);
      final newFilename = '$baseName-annotated$extension';
      final savePath = p.join(directory, newFilename);
      
      // Use savePath to write the annotated file
      // In a real implementation, you would use a PDF library to save the document
      _logger.info('Saving annotated document to: $savePath');
      // Example: await File(savePath).writeAsBytes(annotatedPdfBytes);
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Annotations saved as $newFilename',
          type: NotificationType.success,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to save annotations: $e',
          type: NotificationType.error,
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _addAnnotation(AnnotationType type, Offset position) {
    setState(() {
      _annotations.add(
        PDFAnnotation(
          type: type,
          page: _currentPage,
          position: position,
          color: _currentColor,
          text: type == AnnotationType.note ? 'Note text' : null,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Annotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAnnotations,
            tooltip: 'Save Annotations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPageControl(isDarkMode),
                Expanded(
                  child: Stack(
                    children: [
                      // PDF preview - in a real app, this would be a PDF viewer
                      Center(
                        child: Container(
                          width: 400,
                          height: 550,
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'PDF Page $_currentPage of $_totalPages',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Tap anywhere to add an annotation',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                // Drawing annotations
                                ...(_annotations
                                    .where((a) => a.page == _currentPage)
                                    .map((a) => _buildAnnotation(a))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Gesture detector for adding annotations
                      GestureDetector(
                        onTapUp: (details) {
                          _addAnnotation(_currentAnnotationType, details.localPosition);
                        },
                      ),
                    ],
                  ),
                ),
                _buildAnnotationsToolbar(isDarkMode),
              ],
            ),
    );
  }

  Widget _buildPageControl(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            tooltip: 'Previous Page',
          ),
          const SizedBox(width: 16),
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationsToolbar(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolbarButton(
                icon: Icons.highlight,
                isSelected: _currentAnnotationType == AnnotationType.highlight,
                onTap: () {
                  setState(() {
                    _currentAnnotationType = AnnotationType.highlight;
                    _currentColor = Colors.yellow.withAlpha(128);
                  });
                },
                tooltip: 'Highlight',
              ),
              _buildToolbarButton(
                icon: Icons.edit,
                isSelected: _currentAnnotationType == AnnotationType.underline,
                onTap: () {
                  setState(() {
                    _currentAnnotationType = AnnotationType.underline;
                    _currentColor = Colors.blue;
                  });
                },
                tooltip: 'Underline',
              ),
              _buildToolbarButton(
                icon: Icons.text_fields,
                isSelected: _currentAnnotationType == AnnotationType.note,
                onTap: () {
                  setState(() {
                    _currentAnnotationType = AnnotationType.note;
                    _currentColor = Colors.green;
                  });
                },
                tooltip: 'Add Note',
              ),
              _buildToolbarButton(
                icon: Icons.delete_forever,
                isSelected: _currentAnnotationType == AnnotationType.strikethrough,
                onTap: () {
                  setState(() {
                    _currentAnnotationType = AnnotationType.strikethrough;
                    _currentColor = Colors.red;
                  });
                },
                tooltip: 'Strikethrough',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorButton(Colors.yellow.withAlpha(128)),
              _buildColorButton(Colors.green.withAlpha(128)),
              _buildColorButton(Colors.blue.withAlpha(128)),
              _buildColorButton(Colors.pink.withAlpha(128)),
              _buildColorButton(Colors.orange.withAlpha(128)),
              _buildColorButton(Colors.red.withAlpha(128)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withAlpha(77) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : null,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: _currentColor == color ? Colors.blue : Colors.grey,
            width: _currentColor == color ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildAnnotation(PDFAnnotation annotation) {
    // This is a placeholder - in a real app, these would be positioned correctly
    // on the PDF page and would have proper UI treatments
    switch (annotation.type) {
      case AnnotationType.highlight:
        return Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(2),
          color: annotation.color,
          child: const Text("Highlighted text"),
        );
      case AnnotationType.underline:
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: annotation.color,
                width: 2,
              ),
            ),
          ),
          child: const Text("Underlined text"),
        );
      case AnnotationType.strikethrough:
        return Container(
          margin: const EdgeInsets.all(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text("Strikethrough text"),
              Positioned(
                top: 10,
                child: Container(
                  height: 2,
                  width: 100,
                  color: annotation.color,
                ),
              ),
            ],
          ),
        );
      case AnnotationType.note:
        return Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: annotation.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            annotation.text ?? 'Note',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }
}

enum AnnotationType {
  highlight,
  underline,
  strikethrough,
  note,
}

class PDFAnnotation {
  final AnnotationType type;
  final int page;
  final Offset position;
  final Color color;
  final String? text;

  PDFAnnotation({
    required this.type,
    required this.page,
    required this.position,
    required this.color,
    this.text,
  });
} 