import 'package:flutter/material.dart';
import 'context_utils.dart';

/// A mixin that provides safe BuildContext handling for State classes
mixin SafeContextMixin<T extends StatefulWidget> on State<T> {
  /// Safely executes an async operation with BuildContext
  Future<R?> safeAsync<R>({
    required Future<R?> Function() operation,
    required void Function(R? result) onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    return ContextUtils.runAsyncWithContext(
      context: context,
      operation: operation,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Safely shows a dialog with BuildContext
  Future<R?> safeShowDialog<R>({
    required Widget Function(BuildContext) builder,
  }) async {
    return ContextUtils.showDialogWithContext(
      context: context,
      builder: builder,
    );
  }

  /// Safely shows a snackbar with BuildContext
  void safeShowSnackBar({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ContextUtils.showSnackBarWithContext(
      context: context,
      message: message,
      duration: duration,
    );
  }

  /// Safely navigates with BuildContext
  Future<R?> safeNavigate<R>({
    required Widget Function(BuildContext) builder,
  }) async {
    return ContextUtils.navigateWithContext(
      context: context,
      builder: builder,
    );
  }

  /// Safely shows a bottom sheet with BuildContext
  Future<R?> safeShowBottomSheet<R>({
    required Widget Function(BuildContext) builder,
  }) async {
    return ContextUtils.showBottomSheetWithContext(
      context: context,
      builder: builder,
    );
  }

  /// Safely shows a menu with BuildContext
  Future<R?> safeShowMenu<R>({
    required RelativeRect position,
    required List<PopupMenuEntry<R>> items,
  }) async {
    return ContextUtils.showMenuWithContext(
      context: context,
      position: position,
      items: items,
    );
  }

  /// Safely executes a callback with BuildContext
  void safeExecute(void Function() callback) {
    ContextUtils.executeWithContext(
      context: context,
      callback: callback,
    );
  }

  /// Safely executes a callback with BuildContext and returns a value
  R? safeExecuteAndReturn<R>(R? Function() callback) {
    return ContextUtils.executeWithContextAndReturn(
      context: context,
      callback: callback,
    );
  }
} 