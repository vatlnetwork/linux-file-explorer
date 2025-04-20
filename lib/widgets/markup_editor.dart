import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/file_item.dart';
import '../services/notification_service.dart';

class MarkupEditor extends StatefulWidget {
  final FileItem fileItem;

  const MarkupEditor({
    super.key,
    required this.fileItem,
  });

  @override
  State<MarkupEditor> createState() => _MarkupEditorState();
}

class _MarkupEditorState extends State<MarkupEditor> {
  late ui.Image? _image;
  List<DrawingPoint?> _drawingPoints = [];
  DrawingMode _drawingMode = DrawingMode.pen;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 5;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      File imageFile = File(widget.fileItem.path);
      final List<int> fileBytes = await imageFile.readAsBytes();
      final Uint8List bytes = Uint8List.fromList(fileBytes);
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      
      setState(() {
        _image = fi.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to load image: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _saveImage() async {
    if (_image == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Create a recorder to capture the drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw original image
      canvas.drawImage(_image!, Offset.zero, Paint());
      
      // Draw all points
      for (int i = 0; i < _drawingPoints.length - 1; i++) {
        if (_drawingPoints[i] != null && _drawingPoints[i + 1] != null) {
          canvas.drawLine(
            _drawingPoints[i]!.offset,
            _drawingPoints[i + 1]!.offset,
            Paint()
              ..color = _drawingPoints[i]!.color
              ..strokeWidth = _drawingPoints[i]!.strokeWidth
              ..strokeCap = StrokeCap.round
          );
        }
      }
      
      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        _image!.width,
        _image!.height,
      );
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (pngBytes != null) {
        // Generate new filename
        final originalName = widget.fileItem.name;
        final extension = p.extension(originalName);
        final baseName = originalName.substring(0, originalName.length - extension.length);
        final directory = p.dirname(widget.fileItem.path);
        final newFilename = '$baseName-edited$extension';
        final savePath = p.join(directory, newFilename);
        
        // Save to file
        final file = File(savePath);
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        
        if (mounted) {
          NotificationService.showNotification(
            context,
            message: 'Image saved as $newFilename',
            type: NotificationType.success,
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        NotificationService.showNotification(
          context,
          message: 'Failed to save image: $e',
          type: NotificationType.error,
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markup Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveImage,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _image == null
              ? Center(
                  child: Text(
                    'Unable to load image for editing',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            _drawingPoints.add(
                              DrawingPoint(
                                offset: details.localPosition,
                                color: _selectedColor,
                                strokeWidth: _strokeWidth,
                              ),
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            _drawingPoints.add(
                              DrawingPoint(
                                offset: details.localPosition,
                                color: _selectedColor,
                                strokeWidth: _strokeWidth,
                              ),
                            );
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            _drawingPoints.add(null); // Add null to represent pen lift
                          });
                        },
                        child: CustomPaint(
                          painter: _DrawingPainter(
                            drawingPoints: _drawingPoints,
                            image: _image!,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    _buildToolbar(isDarkMode),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _drawingPoints.clear();
          });
        },
        tooltip: 'Clear',
        child: const Icon(Icons.clear),
      ),
    );
  }

  Widget _buildToolbar(bool isDarkMode) {
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
                icon: Icons.edit,
                isSelected: _drawingMode == DrawingMode.pen,
                onTap: () {
                  setState(() {
                    _drawingMode = DrawingMode.pen;
                  });
                },
                tooltip: 'Pen',
              ),
              _buildToolbarButton(
                icon: Icons.highlight,
                isSelected: _drawingMode == DrawingMode.highlighter,
                onTap: () {
                  setState(() {
                    _drawingMode = DrawingMode.highlighter;
                    _selectedColor = Colors.yellow.withOpacity(0.5);
                    _strokeWidth = 20;
                  });
                },
                tooltip: 'Highlighter',
              ),
              _buildToolbarButton(
                icon: Icons.text_fields,
                isSelected: _drawingMode == DrawingMode.text,
                onTap: () {
                  setState(() {
                    _drawingMode = DrawingMode.text;
                  });
                  // TODO: Implement text mode
                  NotificationService.showNotification(
                    context,
                    message: 'Text tool coming soon!',
                    type: NotificationType.info,
                  );
                },
                tooltip: 'Text',
              ),
              _buildToolbarButton(
                icon: Icons.shape_line,
                isSelected: _drawingMode == DrawingMode.shape,
                onTap: () {
                  setState(() {
                    _drawingMode = DrawingMode.shape;
                  });
                  // TODO: Implement shape mode
                  NotificationService.showNotification(
                    context,
                    message: 'Shape tool coming soon!',
                    type: NotificationType.info,
                  );
                },
                tooltip: 'Shapes',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Stroke Width: '),
              Slider(
                value: _strokeWidth,
                min: 1,
                max: 30,
                divisions: 29,
                label: _strokeWidth.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _strokeWidth = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorButton(Colors.red),
              _buildColorButton(Colors.blue),
              _buildColorButton(Colors.green),
              _buildColorButton(Colors.yellow),
              _buildColorButton(Colors.purple),
              _buildColorButton(Colors.black),
              _buildColorButton(Colors.white),
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
            color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
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
          _selectedColor = color;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: _selectedColor == color ? Colors.blue : Colors.grey,
            width: _selectedColor == color ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final ui.Image image;

  _DrawingPainter({
    required this.drawingPoints,
    required this.image,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scaling to fit the image
    double scaleX = size.width / image.width;
    double scaleY = size.height / image.height;
    double scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Center the image
    double dx = (size.width - image.width * scale) / 2;
    double dy = (size.height - image.height * scale) / 2;
    
    // Draw image
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(dx, dy, image.width * scale, image.height * scale),
      Paint(),
    );
    
    // Draw points
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          Paint()
            ..color = drawingPoints[i]!.color
            ..strokeWidth = drawingPoints[i]!.strokeWidth
            ..strokeCap = StrokeCap.round
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.drawingPoints != drawingPoints;
  }
}

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
  });
}

enum DrawingMode {
  pen,
  highlighter,
  text,
  shape,
} 