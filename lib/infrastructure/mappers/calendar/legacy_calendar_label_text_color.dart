import 'dart:math' as math;

String legacyCalendarLabelTextColor(String color) {
  final rgb = int.parse(color.substring(1), radix: 16);
  double linear(int component) {
    final value = component / 255;
    return value <= .04045
        ? value / 12.92
        : math.pow((value + .055) / 1.055, 2.4).toDouble();
  }

  final luminance =
      .2126 * linear(rgb >> 16) +
      .7152 * linear((rgb >> 8) & 255) +
      .0722 * linear(rgb & 255);
  return luminance > .179 ? '#000000' : '#FFFFFF';
}
