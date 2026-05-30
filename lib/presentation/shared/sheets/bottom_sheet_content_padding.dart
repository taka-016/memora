import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _contentHorizontalPadding = 16;
const double _contentTopPadding = 16;
const double _contentBottomPadding = 16;

EdgeInsets bottomSheetContentPadding(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final bottomSafeArea = math.max(
    mediaQuery.viewInsets.bottom,
    mediaQuery.viewPadding.bottom,
  );

  return EdgeInsets.only(
    left: _contentHorizontalPadding,
    right: _contentHorizontalPadding,
    top: _contentTopPadding,
    bottom: bottomSafeArea + _contentBottomPadding,
  );
}
