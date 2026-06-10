import 'package:flutter/material.dart';

class LocationDetailPanelFrame extends StatelessWidget {
  const LocationDetailPanelFrame({
    super.key,
    required this.panelKey,
    required this.onClose,
    required this.child,
    this.maxHeight,
    this.locationName,
    this.locationNameFieldKey,
    this.onLocationNameChanged,
    this.onPreviousLocation,
    this.onNextLocation,
  });

  final Key panelKey;
  final VoidCallback onClose;
  final Widget child;
  final double? maxHeight;
  final String? locationName;
  final Key? locationNameFieldKey;
  final ValueChanged<String>? onLocationNameChanged;
  final VoidCallback? onPreviousLocation;
  final VoidCallback? onNextLocation;

  @override
  Widget build(BuildContext context) {
    final locationNameWidget = buildLocationName();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            key: panelKey,
            width: double.infinity,
            constraints: maxHeight == null
                ? const BoxConstraints()
                : BoxConstraints(maxHeight: maxHeight!),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LocationNavigationButton(
                  key: const Key('location_detail_previous_button'),
                  tooltip: '前のピンへ移動',
                  icon: Icons.chevron_left,
                  onPressed: onPreviousLocation,
                ),
                Expanded(
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
                      if (locationNameWidget != null) ...[
                        locationNameWidget,
                        const SizedBox(height: 8),
                      ],
                      child,
                    ],
                  ),
                ),
                _LocationNavigationButton(
                  key: const Key('location_detail_next_button'),
                  tooltip: '次のピンへ移動',
                  icon: Icons.chevron_right,
                  onPressed: onNextLocation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? buildLocationName() {
    final name = locationName;
    if (name == null) {
      return null;
    }

    final onChanged = onLocationNameChanged;
    if (onChanged != null) {
      return TextFormField(
        key: locationNameFieldKey,
        initialValue: name,
        decoration: const InputDecoration(
          labelText: '場所名',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      );
    }

    final displayName = name.isNotEmpty ? name : '場所名未設定';
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        displayName,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LocationNavigationButton extends StatelessWidget {
  const _LocationNavigationButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(tooltip: tooltip, onPressed: onPressed, icon: Icon(icon));
  }
}
