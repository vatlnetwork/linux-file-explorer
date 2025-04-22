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
  final DrawingController _drawingController = DrawingController();
  DrawingMode _drawingMode = DrawingMode.pen;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 5;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Text mode properties
  String _textInput = '';
  Offset? _textPosition;
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 18.0;
  
  // Shape mode properties
  ShapeType _selectedShape = ShapeType.rectangle;
  Offset? _shapeStartPosition;
  Offset? _shapeEndPosition;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _drawingController.dispose();
    super.dispose();
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
      final size = Size(_image!.width.toDouble(), _image!.height.toDouble());
      
      // Draw original image
      canvas.drawImage(_image!, Offset.zero, Paint());
      
      // Draw all points using the controller's drawOnCanvas method
      _drawingController.drawOnCanvas(canvas, size, null);
      
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
            icon: const Icon(Icons.undo),
            onPressed: _drawingController.canUndo ? () {
              _drawingController.undo();
            } : null,
            tooltip: 'Undo',
          ),
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
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onPanStart: (details) {
                            if (_drawingMode == DrawingMode.text && _textInput.isNotEmpty) {
                              _textPosition = details.localPosition;
                              // Add the text as a TextPoint and clear input
                              _drawingController.addTextPoint(
                                TextPoint(
                                  offset: _textPosition!,
                                  text: _textInput,
                                  color: _selectedColor,
                                  fontSize: _fontSize,
                                ),
                              );
                              setState(() {
                                _textInput = '';
                                _textController.clear();
                              });
                              return;
                            }
                            
                            if (_drawingMode == DrawingMode.shape) {
                              _shapeStartPosition = details.localPosition;
                              _shapeEndPosition = details.localPosition;
                              // Don't add the shape to points yet, just track start/end positions
                              _drawingController.setActiveShape(
                                ShapePoint(
                                  start: _shapeStartPosition!,
                                  end: _shapeEndPosition!,
                                  color: _selectedColor,
                                  strokeWidth: _strokeWidth,
                                  shapeType: _selectedShape,
                                ),
                              );
                              return;
                            }
                            
                            // For drawing modes like pen and highlighter
                            _drawingController.startDrawing(
                              details.localPosition,
                              _selectedColor,
                              _strokeWidth,
                            );
                          },
                          onPanUpdate: (details) {
                            if (_drawingMode == DrawingMode.shape) {
                              _shapeEndPosition = details.localPosition;
                              // Update the active shape
                              _drawingController.updateActiveShape(
                                ShapePoint(
                                  start: _shapeStartPosition!,
                                  end: _shapeEndPosition!,
                                  color: _selectedColor,
                                  strokeWidth: _strokeWidth,
                                  shapeType: _selectedShape,
                                ),
                              );
                              return;
                            }
                            
                            // For drawing modes like pen and highlighter
                            _drawingController.updateDrawing(details.localPosition);
                          },
                          onPanEnd: (_) {
                            if (_drawingMode == DrawingMode.shape && 
                                _shapeStartPosition != null && 
                                _shapeEndPosition != null) {
                              // Add the final shape
                              _drawingController.endActiveShape();
                              setState(() {
                                _shapeStartPosition = null;
                                _shapeEndPosition = null;
                              });
                              return;
                            }
                            
                            // For drawing modes like pen and highlighter
                            _drawingController.endDrawing();
                          },
                          child: CustomPaint(
                            painter: _DrawingPainter(
                              drawingController: _drawingController,
                              image: _image!,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                    _buildToolbar(isDarkMode),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _drawingController.clear();
          setState(() {});
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
                    _selectedColor = Colors.yellow.withValues(alpha: 0.5);
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
                  _showTextInputDialog();
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
                  _showShapeSelector();
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
            color: isSelected ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
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

  void _showTextInputDialog() {
    // Create local copies to track changes in the dialog
    double dialogFontSize = _fontSize;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Text'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Font Size: '),
                  Expanded(
                    child: Slider(
                      value: dialogFontSize,
                      min: 10,
                      max: 48,
                      divisions: 38,
                      label: dialogFontSize.round().toString(),
                      onChanged: (value) {
                        // Use setDialogState to update within the dialog
                        setDialogState(() {
                          dialogFontSize = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              // Preview text with selected font size
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  _textController.text.isNotEmpty ? _textController.text : 'Preview Text',
                  style: TextStyle(
                    fontSize: dialogFontSize,
                    color: _selectedColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _textInput = _textController.text;
                // Update parent's font size with the dialog value
                setState(() {
                  _fontSize = dialogFontSize;
                });
                Navigator.pop(context);
                // After dialog closes, wait for tap to position text
                if (_textInput.isNotEmpty) {
                  NotificationService.showNotification(
                    context,
                    message: 'Tap on the image to place text',
                    type: NotificationType.info,
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShapeSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Shape'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.rectangle_outlined),
              title: const Text('Rectangle'),
              selected: _selectedShape == ShapeType.rectangle,
              onTap: () {
                setState(() {
                  _selectedShape = ShapeType.rectangle;
                });
                Navigator.pop(context);
                NotificationService.showNotification(
                  context,
                  message: 'Drag to draw a rectangle',
                  type: NotificationType.info,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Circle'),
              selected: _selectedShape == ShapeType.circle,
              onTap: () {
                setState(() {
                  _selectedShape = ShapeType.circle;
                });
                Navigator.pop(context);
                NotificationService.showNotification(
                  context,
                  message: 'Drag to draw a circle',
                  type: NotificationType.info,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.linear_scale),
              title: const Text('Line'),
              selected: _selectedShape == ShapeType.line,
              onTap: () {
                setState(() {
                  _selectedShape = ShapeType.line;
                });
                Navigator.pop(context);
                NotificationService.showNotification(
                  context,
                  message: 'Drag to draw a line',
                  type: NotificationType.info,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.change_history_outlined),
              title: const Text('Triangle'),
              selected: _selectedShape == ShapeType.triangle,
              onTap: () {
                setState(() {
                  _selectedShape = ShapeType.triangle;
                });
                Navigator.pop(context);
                NotificationService.showNotification(
                  context,
                  message: 'Drag to draw a triangle',
                  type: NotificationType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DrawingController extends ChangeNotifier {
  final List<DrawingPoint?> _drawingPoints = [];
  final List<DrawingPoint> _currentStroke = [];
  ShapePoint? _activeShape;
  
  // History management
  final List<List<DrawingPoint?>> _history = [];
  final int _maxHistoryLength = 50; // Limit history to prevent memory issues
  
  List<DrawingPoint?> get drawingPoints => _drawingPoints;
  ShapePoint? get activeShape => _activeShape;
  bool get canUndo => _history.isNotEmpty;
  
  void startDrawing(Offset offset, Color color, double strokeWidth) {
    final point = DrawingPoint(
      offset: offset,
      color: color,
      strokeWidth: strokeWidth,
    );
    _currentStroke.add(point);
    notifyListeners();
  }
  
  void updateDrawing(Offset offset) {
    if (_currentStroke.isEmpty) return;
    
    final lastPoint = _currentStroke.last;
    final newPoint = DrawingPoint(
      offset: offset,
      color: lastPoint.color,
      strokeWidth: lastPoint.strokeWidth,
    );
    _currentStroke.add(newPoint);
    notifyListeners();
  }
  
  void endDrawing() {
    if (_currentStroke.isEmpty) return;
    
    // Save state to history before making changes
    _saveToHistory();
    
    _drawingPoints.addAll(_currentStroke);
    _drawingPoints.add(null); // Add null to represent pen lift
    _currentStroke.clear();
    notifyListeners();
  }
  
  void setActiveShape(ShapePoint shape) {
    _activeShape = shape;
    notifyListeners();
  }
  
  void updateActiveShape(ShapePoint shape) {
    _activeShape = shape;
    notifyListeners();
  }
  
  void endActiveShape() {
    if (_activeShape != null) {
      // Save state to history before making changes
      _saveToHistory();
      
      _drawingPoints.add(_activeShape);
      _activeShape = null;
      notifyListeners();
    }
  }
  
  void addTextPoint(TextPoint textPoint) {
    // Save state to history before making changes
    _saveToHistory();
    
    _drawingPoints.add(textPoint);
    notifyListeners();
  }
  
  void clear() {
    if (_drawingPoints.isEmpty) return;
    
    // Save state to history before clearing
    _saveToHistory();
    
    _drawingPoints.clear();
    _currentStroke.clear();
    _activeShape = null;
    notifyListeners();
  }
  
  void undo() {
    if (_history.isEmpty) return;
    
    // Restore previous state
    _drawingPoints.clear();
    _drawingPoints.addAll(_history.last);
    _history.removeLast();
    notifyListeners();
  }
  
  void _saveToHistory() {
    // Create a copy of current state and add to history
    final stateCopy = List<DrawingPoint?>.from(_drawingPoints);
    _history.add(stateCopy);
    
    // Limit history size
    if (_history.length > _maxHistoryLength) {
      _history.removeAt(0);
    }
  }
  
  void drawOnCanvas(Canvas canvas, Size size, Size? viewportSize) {
    // Draw permanent points
    for (int i = 0; i < _drawingPoints.length - 1; i++) {
      if (_drawingPoints[i] != null && _drawingPoints[i + 1] != null) {
        // Skip if it's a TextPoint or ShapePoint
        if (_drawingPoints[i] is TextPoint || _drawingPoints[i] is ShapePoint) continue;
        
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
    
    // Draw current stroke (for real-time feedback)
    for (int i = 0; i < _currentStroke.length - 1; i++) {
      canvas.drawLine(
        _currentStroke[i].offset,
        _currentStroke[i + 1].offset,
        Paint()
          ..color = _currentStroke[i].color
          ..strokeWidth = _currentStroke[i].strokeWidth
          ..strokeCap = StrokeCap.round
      );
    }
    
    // Draw shape points
    for (final point in _drawingPoints) {
      if (point is ShapePoint) {
        _drawShape(canvas, point);
      }
    }
    
    // Draw the active shape (while dragging)
    if (_activeShape != null) {
      _drawShape(canvas, _activeShape!);
    }
    
    // Draw text points separately
    for (final point in _drawingPoints) {
      if (point is TextPoint) {
        final textSpan = TextSpan(
          text: point.text,
          style: TextStyle(
            color: point.color,
            fontSize: point.fontSize,
            fontWeight: FontWeight.bold,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, point.offset);
      }
    }
  }

  void _drawShape(Canvas canvas, ShapePoint shape) {
    final paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke;
      
    switch (shape.shapeType) {
      case ShapeType.rectangle:
        canvas.drawRect(
          Rect.fromPoints(shape.start, shape.end),
          paint,
        );
        break;
      case ShapeType.circle:
        final center = Offset(
          (shape.start.dx + shape.end.dx) / 2,
          (shape.start.dy + shape.end.dy) / 2,
        );
        final radius = (shape.start - shape.end).distance / 2;
        canvas.drawCircle(center, radius, paint);
        break;
      case ShapeType.line:
        canvas.drawLine(shape.start, shape.end, paint);
        break;
      case ShapeType.triangle:
        final path = Path();
        path.moveTo(
          (shape.start.dx + shape.end.dx) / 2,
          shape.start.dy,
        );
        path.lineTo(shape.start.dx, shape.end.dy);
        path.lineTo(shape.end.dx, shape.end.dy);
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }
}

class _DrawingPainter extends CustomPainter {
  final DrawingController drawingController;
  final ui.Image image;

  _DrawingPainter({
    required this.drawingController,
    required this.image,
  }) : super(repaint: drawingController);

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
    
    // Delegate drawing to the controller
    drawingController.drawOnCanvas(canvas, size, size);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true; // Let the ChangeNotifier handle repaint optimization
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

class TextPoint extends DrawingPoint {
  final String text;
  final double fontSize;

  TextPoint({
    required super.offset,
    required super.color,
    required this.text,
    required this.fontSize,
  }) : super(strokeWidth: 1.0);
}

class ShapePoint extends DrawingPoint {
  final Offset start;
  final Offset end;
  final ShapeType shapeType;

  ShapePoint({
    required this.start,
    required this.end,
    required super.color,
    required super.strokeWidth,
    required this.shapeType,
  }) : super(offset: start);
}

enum DrawingMode {
  pen,
  highlighter,
  text,
  shape,
}

enum ShapeType {
  rectangle,
  circle,
  line,
  triangle,
} 