import 'package:flutter/material.dart';

/// A service to display consistent, themed notifications throughout the app
/// with a custom look and positioning in the right side
class NotificationService {
  /// Shows a notification (SnackBar) in the right side of the screen
  /// The notification follows the app theme and fits its content
  static void showNotification(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    NotificationType type = NotificationType.info,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine icon and color based on notification type
    IconData icon;
    Color backgroundColor;
    Color textColor;
    
    switch (type) {
      case NotificationType.success:
        icon = Icons.check_circle_outline;
        backgroundColor = isDarkMode ? Colors.green.shade800 : Colors.green.shade100;
        textColor = isDarkMode ? Colors.white : Colors.green.shade800;
        break;
      case NotificationType.error:
        icon = Icons.error_outline;
        backgroundColor = isDarkMode ? Colors.red.shade800 : Colors.red.shade100;
        textColor = isDarkMode ? Colors.white : Colors.red.shade800;
        break;
      case NotificationType.warning:
        icon = Icons.warning_amber_outlined;
        backgroundColor = isDarkMode ? Colors.amber.shade800 : Colors.amber.shade100;
        textColor = isDarkMode ? Colors.white : Colors.amber.shade900;
        break;
      case NotificationType.info:
        icon = Icons.info_outline;
        backgroundColor = isDarkMode 
          ? Colors.blueGrey.shade700 
          : Colors.blue.shade50;
        textColor = isDarkMode ? Colors.white : Colors.blue.shade800;
        break;
    }

    // Calculate width based on text length
    final textSpan = TextSpan(
      text: message,
      style: const TextStyle(fontSize: 14),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: MediaQuery.of(context).size.width * 0.4);
    
    // Check if message contains line breaks
    final bool hasLineBreaks = message.contains('\n');
    // Calculate desired width (text width + icon + padding)
    final double contentWidth = textPainter.width + 34;
    // Maximum width available
    final double maxWidth = MediaQuery.of(context).size.width * 0.4;
    
    // Dismiss all current notifications before showing a new one
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final snackBar = SnackBar(
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      duration: duration,
      // Set small fixed padding to minimize empty space
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: EdgeInsets.only(
        bottom: 16, 
        right: 16,
        // Push notification to the right
        left: MediaQuery.of(context).size.width * 0.6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      content: Container(
        width: contentWidth > maxWidth ? maxWidth : contentWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: hasLineBreaks ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: textColor, 
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Types of notifications to display with different styling
enum NotificationType {
  info,
  success,
  warning,
  error,
} 