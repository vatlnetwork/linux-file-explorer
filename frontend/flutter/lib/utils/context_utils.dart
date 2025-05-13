import 'package:flutter/material.dart';

/// A utility class for safely handling BuildContext across async operations
class ContextUtils {
  /// Safely executes an async operation with BuildContext
  static Future<T?> runAsyncWithContext<T>({
    required BuildContext context,
    required Future<T?> Function() operation,
    required void Function(T? result) onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    if (!context.mounted) return null;

    try {
      final result = await operation();
      if (context.mounted) {
        onSuccess(result);
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        onError?.call(e);
      }
      return null;
    }
  }

  /// Safely shows a dialog with BuildContext
  static Future<T?> showDialogWithContext<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) async {
    if (!context.mounted) return null;
    return showDialog<T>(context: context, builder: builder);
  }

  /// Safely shows a snackbar with BuildContext
  static void showSnackBarWithContext({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Safely navigates with BuildContext
  static Future<T?> navigateWithContext<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) async {
    if (!context.mounted) return null;
    return Navigator.push<T>(
      context,
      MaterialPageRoute(builder: builder),
    );
  }

  /// Safely shows a bottom sheet with BuildContext
  static Future<T?> showBottomSheetWithContext<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) async {
    if (!context.mounted) return null;
    return showModalBottomSheet<T>(
      context: context,
      builder: builder,
    );
  }

  /// Safely shows a menu with BuildContext
  static Future<T?> showMenuWithContext<T>({
    required BuildContext context,
    required RelativeRect position,
    required List<PopupMenuEntry<T>> items,
  }) async {
    if (!context.mounted) return null;
    return showMenu<T>(
      context: context,
      position: position,
      items: items,
    );
  }

  /// Safely executes a callback with BuildContext
  static void executeWithContext({
    required BuildContext context,
    required void Function() callback,
  }) {
    if (!context.mounted) return;
    callback();
  }

  /// Safely executes a callback with BuildContext and returns a value
  static T? executeWithContextAndReturn<T>({
    required BuildContext context,
    required T? Function() callback,
  }) {
    if (!context.mounted) return null;
    return callback();
  }
} 