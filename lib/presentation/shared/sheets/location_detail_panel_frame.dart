import 'package:flutter/material.dart';

class LocationDetailPanelFrame extends StatelessWidget {
  const LocationDetailPanelFrame({
    super.key,
    required this.panelKey,
    required this.onClose,
    required this.child,
  });

  final Key panelKey;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            key: panelKey,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: '閉じる',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
