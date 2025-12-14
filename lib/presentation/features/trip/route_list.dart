part of 'route_info_view.dart';

class RouteListSection extends StatelessWidget {
  const RouteListSection({
    super.key,
    required this.pins,
    required this.segmentModes,
    required this.segmentDetails,
    required this.routeMemoExpansion,
    required this.selectedPinIndex,
    required this.onReorder,
    required this.onPinTap,
    required this.onModeChanged,
    required this.onToggleRouteMemo,
    required this.onOpenOtherRouteInfoSheet,
    required this.segmentKeyBuilder,
  });

  final List<PinDto> pins;
  final Map<String, TravelMode> segmentModes;
  final Map<String, RouteSegmentDetail> segmentDetails;
  final Map<String, bool> routeMemoExpansion;
  final int? selectedPinIndex;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onPinTap;
  final void Function(String key, TravelMode mode) onModeChanged;
  final void Function(String key) onToggleRouteMemo;
  final Future<void> Function(String key) onOpenOtherRouteInfoSheet;
  final String Function(PinDto origin, PinDto destination) segmentKeyBuilder;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('route_info_list_area'),
      children: [Positioned.fill(child: _buildReorderableList())],
    );
  }

  Widget _buildReorderableList() {
    return Material(
      color: Colors.transparent,
      child: ReorderableListView.builder(
        key: const Key('route_info_reorderable_list'),
        padding: const EdgeInsets.only(right: 12),
        shrinkWrap: true,
        primary: false,
        cacheExtent: double.infinity,
        onReorder: onReorder,
        itemCount: pins.length,
        itemBuilder: (context, index) {
          final pin = pins[index];
          return Column(
            key: ValueKey(pin.pinId),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPinListItem(pin, index),
              if (index < pins.length - 1) _buildRouteSegment(index),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPinListItem(PinDto pin, int index) {
    return Card(
      child: ListTile(
        key: Key('route_info_pin_tile_${pin.pinId}'),
        title: Text(pin.locationName ?? ''),
        selected: selectedPinIndex == index,
        onTap: () => onPinTap(index),
        trailing: const Icon(Icons.drag_handle),
      ),
    );
  }

  Widget _buildRouteSegment(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 12),
        const Icon(Icons.arrow_downward),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTravelModeDropdown(index),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Container(
                  key: Key('route_segment_container_$index'),
                  child: _buildRouteMemoView(index),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelModeDropdown(int index) {
    final key = segmentKeyBuilder(pins[index], pins[index + 1]);
    final currentMode = segmentModes[key] ?? TravelMode.drive;
    final dropdown = DropdownButton<TravelMode>(
      key: Key('route_segment_mode_$index'),
      value: currentMode,
      underline: const SizedBox.shrink(),
      items: TravelMode.values
          .map(
            (mode) => DropdownMenuItem<TravelMode>(
              value: mode,
              child: Text(mode.label),
            ),
          )
          .toList(),
      onChanged: (mode) {
        if (mode == null) return;
        onModeChanged(key, mode);
      },
    );

    if (currentMode != TravelMode.other) {
      return dropdown;
    }

    return Row(
      children: [
        Flexible(fit: FlexFit.loose, child: dropdown),
        IconButton(
          key: Key('route_segment_other_route_icon_$index'),
          onPressed: () => onOpenOtherRouteInfoSheet(key),
          icon: const Icon(Icons.edit),
          tooltip: '経路入力',
        ),
      ],
    );
  }

  Widget _buildRouteMemoView(int index) {
    final key = segmentKeyBuilder(pins[index], pins[index + 1]);
    final detail = segmentDetails[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRouteMemoToggle(index, key),
        _buildRouteMemo(index, key, detail),
      ],
    );
  }

  Widget _buildRouteMemoToggle(int index, String key) {
    final isExpanded = routeMemoExpansion[key] ?? false;

    return InkWell(
      key: Key('route_memo_toggle_button_$index'),
      onTap: () => onToggleRouteMemo(key),
      child: Row(
        key: Key('route_memo_toggle_label_$index'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'ルートメモ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMemo(int index, String key, RouteSegmentDetail? detail) {
    final isExpanded = routeMemoExpansion[key] ?? false;
    const double maxDetailHeight = 120.0;
    final memoEntries = detail == null
        ? <Widget>[]
        : _buildRouteMemoEntries(detail);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isExpanded
          ? Padding(
              key: ValueKey('route_memo_$index'),
              padding: const EdgeInsets.only(left: 24, top: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: maxDetailHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: memoEntries,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('route_memo_collapsed')),
    );
  }

  List<Widget> _buildRouteMemoEntries(RouteSegmentDetail detail) {
    final entries = <Widget>[];
    final distanceLabel = _formatDistanceLabel(detail.distanceMeters);
    final durationMinutes = _durationMinutes(detail.durationSeconds);

    if (detail.distanceMeters > 0) {
      entries.add(_buildMemoLabel('距離: 約${distanceLabel}km'));
    }
    if (durationMinutes > 0) {
      entries.add(_buildMemoLabel('所要時間: 約$durationMinutes分'));
    }
    if (detail.instructions.isNotEmpty) {
      entries.add(_buildMemoLabel('経路案内'));
      entries.addAll(
        detail.instructions
            .map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(instruction, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
      );
    }

    return entries;
  }

  Widget _buildMemoLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatDistanceLabel(int meters) {
    if (meters <= 0) {
      return '0.0';
    }
    final distance = meters / 1000;
    final formatted = distance >= 100
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  int _durationMinutes(int seconds) {
    if (seconds <= 0) {
      return 0;
    }
    return (seconds / 60).ceil();
  }
}
