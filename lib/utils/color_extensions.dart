import 'package:flutter/material.dart';

/// Provides utility extension methods for Flutter's [Color] class
extension ColorExtensions on Color {
  /// Creates a copy of this color with modified values.
  /// 
  /// The [alpha], [red], [green], and [blue] parameters can be used to override
  /// the respective color components. If any parameter is not provided,
  /// the original value is used.
  Color withValues({int? alpha, int? red, int? green, int? blue}) {
    return Color.fromARGB(
      alpha ?? a.toInt(),
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
    );
  }
} 