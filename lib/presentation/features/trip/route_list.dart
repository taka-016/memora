part of 'route_info_view.dart';

class RouteList extends HookWidget {
  const RouteList({
    super.key,
    required this.pinsState,
    required this.segmentModesState,
    required this.segmentDetailsState,
    required this.routeMemoExpansionState,
    required this.selectedPinIndexState,
  });

  final ValueNotifier<List<PinDto>> pinsState;
  final ValueNotifier<Map<String, TravelMode>> segmentModesState;
  final ValueNotifier<Map<String, RouteSegmentDetail>> segmentDetailsState;
  final ValueNotifier<Map<String, bool>> routeMemoExpansionState;
  final ValueNotifier<int?> selectedPinIndexState;

  @override
  Widget build(BuildContext context) {
    useListenable(pinsState);
    useListenable(segmentModesState);
    useListenable(segmentDetailsState);
    useListenable(routeMemoExpansionState);
    useListenable(selectedPinIndexState);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) {
          return;
        }
        segmentModesState.value = buildSegmentModes({});
      });
      return null;
    }, const []);

    final pins = pinsState.value;
    final segmentModes = segmentModesState.value;
    final segmentDetails = segmentDetailsState.value;
    final routeMemoExpansion = routeMemoExpansionState.value;
    final selectedPinIndex = selectedPinIndexState.value;

    void onReorder(int oldIndex, int newIndex) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updatedPins = List<PinDto>.from(pinsState.value);
      final previousDetails = Map<String, RouteSegmentDetail>.from(
        segmentDetailsState.value,
      );
      final item = updatedPins.removeAt(oldIndex);
      updatedPins.insert(newIndex, item);
      pinsState.value = updatedPins;
      final nextModes = buildSegmentModes(segmentModesState.value);
      segmentModesState.value = nextModes;
      segmentDetailsState.value = retainManualDetails(
        previousDetails,
        nextModes,
      );
      routeMemoExpansionState.value = {};
      selectedPinIndexState.value = null;
    }

    void onPinTap(int index) {
      if (selectedPinIndexState.value == index) {
        selectedPinIndexState.value = null;
      } else {
        selectedPinIndexState.value = index;
      }
    }

    void onModeChanged(String key, TravelMode mode) {
      final previousMode = segmentModesState.value[key];
      if (previousMode == mode) {
        return;
      }
      segmentModesState.value = {...segmentModesState.value, key: mode};
      if (mode == TravelMode.other || previousMode == TravelMode.other) {
        final updated = Map<String, RouteSegmentDetail>.from(
          segmentDetailsState.value,
        )..remove(key);
        segmentDetailsState.value = updated;
      }
    }

    void toggleRouteMemoExpansion(String key) {
      final current = routeMemoExpansionState.value[key] ?? false;
      routeMemoExpansionState.value = {
        ...routeMemoExpansionState.value,
        key: !current,
      };
    }

    Future<void> openOtherRouteInfoSheet(String key) async {
      final initialDetail =
          segmentDetailsState.value[key] ?? const RouteSegmentDetail.empty();

      final result = await showModalBottomSheet<RouteSegmentDetail>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return RouteMemoEditBottomSheet(
            initialDetail: initialDetail,
            onChanged: (value) =>
                scheduleManualRouteUpdate(context, key, value),
          );
        },
      );

      if (!context.mounted) {
        return;
      }

      if (result != null) {
        scheduleManualRouteUpdate(context, key, result);
      }
    }

    return Stack(
      key: const Key('route_info_list_area'),
      children: [
        Positioned.fill(
          child: buildReorderableList(
            pins: pins,
            selectedPinIndex: selectedPinIndex,
            segmentModes: segmentModes,
            segmentDetails: segmentDetails,
            routeMemoExpansion: routeMemoExpansion,
            onReorder: onReorder,
            onPinTap: onPinTap,
            onModeChanged: onModeChanged,
            onToggleRouteMemo: toggleRouteMemoExpansion,
            onOpenOtherRouteInfoSheet: openOtherRouteInfoSheet,
          ),
        ),
      ],
    );
  }

  Widget buildReorderableList({
    required List<PinDto> pins,
    required int? selectedPinIndex,
    required Map<String, TravelMode> segmentModes,
    required Map<String, RouteSegmentDetail> segmentDetails,
    required Map<String, bool> routeMemoExpansion,
    required void Function(int oldIndex, int newIndex) onReorder,
    required void Function(int index) onPinTap,
    required void Function(String key, TravelMode mode) onModeChanged,
    required void Function(String key) onToggleRouteMemo,
    required Future<void> Function(String key) onOpenOtherRouteInfoSheet,
  }) {
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
              buildPinListItem(pin, index, selectedPinIndex, onPinTap),
              if (index < pins.length - 1)
                buildRouteSegment(
                  context: context,
                  index: index,
                  pins: pins,
                  segmentModes: segmentModes,
                  segmentDetails: segmentDetails,
                  routeMemoExpansion: routeMemoExpansion,
                  onModeChanged: onModeChanged,
                  onToggleRouteMemo: onToggleRouteMemo,
                  onOpenOtherRouteInfoSheet: onOpenOtherRouteInfoSheet,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildPinListItem(
    PinDto pin,
    int index,
    int? selectedPinIndex,
    void Function(int index) onPinTap,
  ) {
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

  Widget buildRouteSegment({
    required BuildContext context,
    required int index,
    required List<PinDto> pins,
    required Map<String, TravelMode> segmentModes,
    required Map<String, RouteSegmentDetail> segmentDetails,
    required Map<String, bool> routeMemoExpansion,
    required void Function(String key, TravelMode mode) onModeChanged,
    required void Function(String key) onToggleRouteMemo,
    required Future<void> Function(String key) onOpenOtherRouteInfoSheet,
  }) {
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
              buildTravelModeDropdown(
                context: context,
                index: index,
                pins: pins,
                segmentModes: segmentModes,
                onModeChanged: onModeChanged,
                onOpenOtherRouteInfoSheet: onOpenOtherRouteInfoSheet,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Container(
                  key: Key('route_segment_container_$index'),
                  child: buildRouteMemoView(
                    index: index,
                    pins: pins,
                    segmentDetails: segmentDetails,
                    routeMemoExpansion: routeMemoExpansion,
                    onToggleRouteMemo: onToggleRouteMemo,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildTravelModeDropdown({
    required BuildContext context,
    required int index,
    required List<PinDto> pins,
    required Map<String, TravelMode> segmentModes,
    required void Function(String key, TravelMode mode) onModeChanged,
    required Future<void> Function(String key) onOpenOtherRouteInfoSheet,
  }) {
    final key = _segmentKey(pins[index], pins[index + 1]);
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
        if (mode == null) {
          return;
        }
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

  Widget buildRouteMemoView({
    required int index,
    required List<PinDto> pins,
    required Map<String, RouteSegmentDetail> segmentDetails,
    required Map<String, bool> routeMemoExpansion,
    required void Function(String key) onToggleRouteMemo,
  }) {
    final key = _segmentKey(pins[index], pins[index + 1]);
    final detail = segmentDetails[key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRouteMemoToggle(index, key, routeMemoExpansion, onToggleRouteMemo),
        buildRouteMemo(index, key, detail, routeMemoExpansion),
      ],
    );
  }

  Widget buildRouteMemoToggle(
    int index,
    String key,
    Map<String, bool> routeMemoExpansion,
    void Function(String key) onToggleRouteMemo,
  ) {
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

  Widget buildRouteMemo(
    int index,
    String key,
    RouteSegmentDetail? detail,
    Map<String, bool> routeMemoExpansion,
  ) {
    final isExpanded = routeMemoExpansion[key] ?? false;
    const double maxDetailHeight = 120.0;
    final memoEntries = detail == null
        ? <Widget>[]
        : buildRouteMemoEntries(detail);

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

  List<Widget> buildRouteMemoEntries(RouteSegmentDetail detail) {
    final entries = <Widget>[];
    final distanceLabel = formatDistanceLabel(detail.distanceMeters);
    final dMinutes = durationMinutes(detail.durationSeconds);

    if (detail.distanceMeters > 0) {
      entries.add(buildMemoLabel('距離: 約${distanceLabel}km'));
    }
    if (dMinutes > 0) {
      entries.add(buildMemoLabel('所要時間: 約$dMinutes分'));
    }
    if (detail.instructions.isNotEmpty) {
      entries.add(buildMemoLabel('経路案内'));
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

  Widget buildMemoLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Map<String, TravelMode> buildSegmentModes(Map<String, TravelMode> previous) {
    final map = <String, TravelMode>{};
    final validKeys = <String>[];
    final currentPins = pinsState.value;
    for (var i = 0; i < currentPins.length - 1; i++) {
      final key = _segmentKey(currentPins[i], currentPins[i + 1]);
      validKeys.add(key);
      map[key] = previous[key] ?? TravelMode.drive;
    }
    cleanupSegmentDetails(validKeys);
    return map;
  }

  void cleanupSegmentDetails(Iterable<String> validKeys) {
    final validKeySet = validKeys.toSet();
    segmentDetailsState.value = Map<String, RouteSegmentDetail>.from(
      segmentDetailsState.value,
    )..removeWhere((key, _) => !validKeySet.contains(key));
  }

  Map<String, RouteSegmentDetail> retainManualDetails(
    Map<String, RouteSegmentDetail> previousDetails,
    Map<String, TravelMode> nextModes,
  ) {
    final retained = <String, RouteSegmentDetail>{};
    for (final entry in nextModes.entries) {
      if (entry.value != TravelMode.other) {
        continue;
      }
      final detail = previousDetails[entry.key];
      if (detail == null || !_hasManualContent(detail)) {
        continue;
      }
      retained[entry.key] = detail;
    }
    return retained;
  }

  void scheduleManualRouteUpdate(
    BuildContext context,
    String key,
    RouteSegmentDetail detail,
  ) {
    final normalized = sanitizeManualDetail(detail);

    void applyUpdate() {
      if (!context.mounted) {
        return;
      }
      final current = segmentDetailsState.value[key];
      final updated = Map<String, RouteSegmentDetail>.from(
        segmentDetailsState.value,
      );
      if (_hasManualContent(normalized)) {
        if (current == null) {
          updated[key] = normalized;
        } else {
          updated[key] = current.copyWith(
            durationSeconds: normalized.durationSeconds,
            instructions: normalized.instructions,
          );
        }
      } else if (current != null) {
        updated[key] = current.copyWith(
          durationSeconds: 0,
          instructions: const [],
        );
      }
      segmentDetailsState.value = updated;
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      applyUpdate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => applyUpdate());
    }
  }

  RouteSegmentDetail sanitizeManualDetail(RouteSegmentDetail detail) {
    final sanitizedInstructions = detail.instructions
        .map((instruction) => instruction.trim())
        .where((instruction) => instruction.isNotEmpty)
        .toList();
    final sanitizedDuration = detail.durationSeconds > 0
        ? detail.durationSeconds
        : 0;
    return detail.copyWith(
      durationSeconds: sanitizedDuration,
      instructions: sanitizedInstructions,
    );
  }

  String formatDistanceLabel(int meters) {
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

  int durationMinutes(int seconds) {
    if (seconds <= 0) {
      return 0;
    }
    return (seconds / 60).ceil();
  }
}

String _segmentKey(PinDto origin, PinDto destination) {
  return _routeSegmentKey(origin, destination);
}
