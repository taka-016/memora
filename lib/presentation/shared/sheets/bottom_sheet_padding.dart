import 'package:flutter/widgets.dart';

double bottomSheetBottomPadding(MediaQueryData mediaQuery) {
  if (mediaQuery.viewInsets.bottom > 0) {
    return mediaQuery.viewInsets.bottom + 16;
  }
  return mediaQuery.viewPadding.bottom > 16
      ? mediaQuery.viewPadding.bottom
      : 16;
}
