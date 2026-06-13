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

  static const double _swipeDistanceThreshold = 80;

  @override
  Widget build(BuildContext context) {
    final locationNameWidget = buildLocationName();
    var horizontalDragOffset = 0.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => horizontalDragOffset = 0,
            onHorizontalDragUpdate: (details) {
              horizontalDragOffset += details.primaryDelta ?? 0;
            },
            onHorizontalDragEnd: (_) {
              handleHorizontalSwipe(horizontalDragOffset);
            },
            child: Container(
              key: panelKey,
              width: double.infinity,
              constraints: maxHeight == null
                  ? const BoxConstraints()
                  : BoxConstraints(maxHeight: maxHeight!),
              padding: const EdgeInsets.fromLTRB(2, 12, 2, 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LocationNavigationButton(
                          key: const Key('location_detail_previous_button'),
                          tooltip: '前のピンへ移動',
                          direction: _LocationNavigationDirection.previous,
                          onPressed: onPreviousLocation,
                        ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                          direction: _LocationNavigationDirection.next,
                          onPressed: onNextLocation,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: 0,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        tooltip: '閉じる',
                        onPressed: onClose,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleHorizontalSwipe(double offset) {
    if (offset.abs() < _swipeDistanceThreshold) {
      return;
    }

    if (offset < 0) {
      onNextLocation?.call();
      return;
    }

    onPreviousLocation?.call();
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
    required this.direction,
    required this.onPressed,
  });

  final String tooltip;
  final _LocationNavigationDirection direction;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = onPressed == null
        ? theme.disabledColor
        : IconTheme.of(context).color ?? theme.iconTheme.color;

    return SizedBox(
      width: 40,
      height: 64,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 64),
        icon: CustomPaint(
          size: const Size(22, 38),
          painter: _LocationNavigationChevronPainter(
            direction: direction,
            color: iconColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

enum _LocationNavigationDirection { previous, next }

class _LocationNavigationChevronPainter extends CustomPainter {
  const _LocationNavigationChevronPainter({
    required this.direction,
    required this.color,
  });

  final _LocationNavigationDirection direction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final isPrevious = direction == _LocationNavigationDirection.previous;
    final edgeX = isPrevious ? size.width * 0.86 : size.width * 0.14;
    final centerX = isPrevious ? size.width * 0.14 : size.width * 0.86;

    final path = Path()
      ..moveTo(edgeX, 0)
      ..lineTo(centerX, size.height / 2)
      ..lineTo(edgeX, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LocationNavigationChevronPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.color != color;
  }
}
