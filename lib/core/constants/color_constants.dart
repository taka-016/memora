import 'package:flutter/material.dart';

class ColorConstants {
  ColorConstants._();

  static const List<Color> sequentialColorPalette = [
    Color(0xFF3949AB),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF5E35B1),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFFD81B60),
  ];

  static Color getSequentialColor(int index) {
    return sequentialColorPalette[index % sequentialColorPalette.length];
  }

  static Color getSequentialColorWithOpacity(int index, double opacity) {
    final baseColor = getSequentialColor(index);
    final dimmedAlpha = (baseColor.a * 255.0 * opacity).round();
    final safeAlpha = dimmedAlpha.clamp(0, 255).toInt();
    return baseColor.withAlpha(safeAlpha);
  }
}
