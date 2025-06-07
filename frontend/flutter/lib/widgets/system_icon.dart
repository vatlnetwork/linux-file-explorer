import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/app_item.dart';
import '../services/app_service.dart';

class SystemIcon extends StatefulWidget {
  final AppItem app;
  final double size;
  final Color? fallbackColor;

  const SystemIcon({
    super.key,
    required this.app,
    required this.size,
    this.fallbackColor,
  });

  @override
  State<SystemIcon> createState() => _SystemIconState();
}

class _SystemIconState extends State<SystemIcon> {
  String? _iconPath;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadIconPath();
  }

  @override
  void didUpdateWidget(SystemIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app.icon != widget.app.icon) {
      _loadIconPath();
    }
  }

  Future<void> _loadIconPath() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final appService = Provider.of<AppService>(context, listen: false);
      _iconPath = await appService.getIconPath(widget.app.icon);

      if (_iconPath == null) {
        _hasError = true;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      debugPrint('Error loading icon for ${widget.app.name}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor =
        widget.fallbackColor ??
        (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700);

    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError || _iconPath == null) {
      return Icon(Icons.apps, size: widget.size, color: fallbackColor);
    }

    // Use Image widget to display icon from file
    final file = File(_iconPath!);
    if (!file.existsSync()) {
      return Icon(Icons.apps, size: widget.size, color: fallbackColor);
    }

    // Display different types of icons
    if (_iconPath!.endsWith('.svg')) {
      final isSymbolicOrMonochrome = _isMonochromeSvg(file);
      final themeColor = Theme.of(context).iconTheme.color;

      // Use flutter_svg for SVG icons with better error handling
      return SvgPicture.file(
        file,
        width: widget.size,
        height: widget.size,
        placeholderBuilder:
            (BuildContext context) =>
                Icon(Icons.apps, size: widget.size, color: fallbackColor),
        // Only apply color filter for symbolic icons, not for regular app icons
        colorFilter:
            isSymbolicOrMonochrome && _iconPath!.contains('-symbolic')
                ? ColorFilter.mode(themeColor ?? fallbackColor, BlendMode.srcIn)
                : null,
        semanticsLabel: '${widget.app.name} icon',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading SVG icon for ${widget.app.name}: $error');
          return Icon(Icons.apps, size: widget.size, color: fallbackColor);
        },
      );
    } else if (_iconPath!.endsWith('.png') || _iconPath!.endsWith('.xpm')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          file,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.apps, size: widget.size, color: fallbackColor);
          },
        ),
      );
    } else {
      // Unknown format, use default icon
      return Icon(Icons.apps, size: widget.size, color: fallbackColor);
    }
  }

  // Helper method to check if an SVG is monochrome or symbolic
  bool _isMonochromeSvg(File file) {
    try {
      final content = file.readAsStringSync();

      // Check if it's a symbolic icon
      if (file.path.contains('-symbolic') ||
          content.contains('class="symbolic"') ||
          content.contains('id="symbolic"')) {
        return true;
      }

      // Check for explicit color definitions
      final hasExplicitColors = RegExp(
        r'(?:fill|stroke)="(?!none)(?!#000)(?!#fff)(?!#ffffff)(?!#000000)(?!currentColor)[^"]+"' // Color attributes
        r'|style="[^"]*(?:fill|stroke):[^;]+"' // Style attributes with colors
        r'|<stop[^>]+stop-color="[^"]+"' // Gradient colors
        r'|<style[^>]*>[^<]*(?:fill|stroke):[^;]+', // CSS style colors
      ).hasMatch(content);

      // If the icon has no explicit colors and uses currentColor, treat it as monochrome
      final usesCurrentColor = content.contains('currentColor');

      return !hasExplicitColors || usesCurrentColor;
    } catch (e) {
      debugPrint('Error checking SVG color: $e');
      return false;
    }
  }
}
