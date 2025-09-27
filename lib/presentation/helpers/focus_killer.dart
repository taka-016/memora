import 'package:flutter/material.dart';

class FocusKiller {
  static final FocusNode _dummyFocusNode = FocusNode();

  static void killFocus() {
    _dummyFocusNode.requestFocus();
  }

  static Widget createDummyFocusWidget() {
    return Positioned(
      left: -1000,
      top: -1000,
      child: Focus(
        focusNode: _dummyFocusNode,
        child: const SizedBox(width: 1, height: 1),
      ),
    );
  }

  static void dispose() {
    _dummyFocusNode.dispose();
  }
}
