import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/timeline_view_state.dart';

class TimelineController {
  TimelineController({
    required this.viewState,
    required this.displaySettings,
    required this.isDraggingOnFixedRow,
    required this.rowScrollControllers,
    required this.showMorePast,
    required this.showMoreFuture,
    required this.updateDisplaySettings,
    required this.refreshTimelineRows,
    required this.onRowResizePointerDown,
    required this.onRowResizePointerMove,
    required this.onRowResizePointerUp,
  });

  final TimelineViewState viewState;
  final TimelineDisplaySettings displaySettings;
  final bool isDraggingOnFixedRow;
  final List<ScrollController> rowScrollControllers;
  final VoidCallback showMorePast;
  final VoidCallback showMoreFuture;
  final void Function(TimelineDisplaySettings settings) updateDisplaySettings;
  final Future<void> Function() refreshTimelineRows;
  final void Function(int rowIndex, PointerDownEvent event)
  onRowResizePointerDown;
  final void Function(int rowIndex, PointerMoveEvent event)
  onRowResizePointerMove;
  final void Function(PointerEvent event) onRowResizePointerUp;

  List<double> get rowHeights => viewState.rowHeights;
  List<int> get visibleYears => viewState.visibleYears;
  int get refreshKey => viewState.refreshKey;

  int yearFromColumnIndex(int columnIndex) {
    return viewState.yearFromColumnIndex(columnIndex);
  }
}

TimelineController useTimelineController({
  required BuildContext context,
  required int totalDataRows,
  required List<double> initialRowHeights,
  required TimelineLayoutConfig layoutConfig,
  required void Function(RefreshTimelineCallback)? onSetRefreshCallback,
}) {
  final viewStateState = useState(
    TimelineViewState.initial(
      baseYear: DateTime.now().year,
      totalDataRows: totalDataRows,
      initialYearRange: layoutConfig.initialYearRange,
      dataRowHeight: layoutConfig.dataRowHeight,
      initialRowHeights: initialRowHeights,
    ),
  );
  final isDraggingOnFixedRowState = useState(false);
  final activeResizePointerState = useState<int?>(null);
  final displaySettingsState = useState(TimelineDisplaySettings.defaults);
  final rowScrollControllers = useMemoized(
    () => List.generate(totalDataRows + 1, (_) => ScrollController()),
    [totalDataRows],
  );
  final isSyncingRef = useRef(false);
  final viewState = viewStateState.value.ensureRowCount(
    totalDataRows: totalDataRows,
    dataRowHeight: layoutConfig.dataRowHeight,
    initialRowHeights: initialRowHeights,
  );

  useEffect(() {
    Future.microtask(() async {
      final loaded = await TimelineDisplaySettings.load();
      if (!context.mounted) {
        return;
      }
      displaySettingsState.value = loaded;
    });
    return null;
  }, []);

  useEffect(() {
    viewStateState.value = viewStateState.value.ensureRowCount(
      totalDataRows: totalDataRows,
      dataRowHeight: layoutConfig.dataRowHeight,
      initialRowHeights: initialRowHeights,
    );
    return null;
  }, [totalDataRows]);

  void syncScrollControllers(int sourceIndex) {
    if (isSyncingRef.value) {
      return;
    }

    final sourceController = rowScrollControllers[sourceIndex];
    if (!sourceController.hasClients) {
      return;
    }

    isSyncingRef.value = true;
    final targetOffset = sourceController.offset;

    for (int index = 0; index < rowScrollControllers.length; index++) {
      if (index == sourceIndex) {
        continue;
      }
      final controller = rowScrollControllers[index];
      if (controller.hasClients) {
        controller.jumpTo(targetOffset);
      }
    }

    isSyncingRef.value = false;
  }

  useEffect(() {
    final listeners = <VoidCallback>[];
    for (int index = 0; index < rowScrollControllers.length; index++) {
      final controller = rowScrollControllers[index];
      void listener() => syncScrollControllers(index);
      controller.addListener(listener);
      listeners.add(() => controller.removeListener(listener));
    }

    return () {
      for (final removeListener in listeners) {
        removeListener();
      }
      for (final controller in rowScrollControllers) {
        controller.dispose();
      }
    };
  }, [rowScrollControllers]);

  Future<void> refreshTimelineRows() async {
    viewStateState.value = viewStateState.value.refreshRows();
  }

  useEffect(() {
    if (onSetRefreshCallback != null) {
      onSetRefreshCallback(refreshTimelineRows);
    }
    return null;
  }, [onSetRefreshCallback]);

  void scrollToCurrentYear() {
    if (rowScrollControllers.isEmpty) {
      return;
    }

    final primaryController = rowScrollControllers.first;
    if (!primaryController.hasClients) {
      return;
    }

    final viewportWidth = primaryController.position.viewportDimension;
    final totalWidth =
        (2 * layoutConfig.buttonColumnWidth) +
        (viewState.visibleYears.length * layoutConfig.yearColumnWidth);
    final scrollOffset = (totalWidth / 2) - (viewportWidth / 2);
    final maxExtent = primaryController.position.maxScrollExtent;
    final targetOffset = scrollOffset.clamp(0.0, maxExtent);

    primaryController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }
      scrollToCurrentYear();
    });
    return null;
  }, [rowScrollControllers]);

  return TimelineController(
    viewState: viewState,
    displaySettings: displaySettingsState.value,
    isDraggingOnFixedRow: isDraggingOnFixedRowState.value,
    rowScrollControllers: rowScrollControllers,
    showMorePast: () {
      viewStateState.value = viewStateState.value.expandPast(
        layoutConfig.yearRangeIncrement,
      );
    },
    showMoreFuture: () {
      viewStateState.value = viewStateState.value.expandFuture(
        layoutConfig.yearRangeIncrement,
      );
    },
    updateDisplaySettings: (settings) {
      displaySettingsState.value = settings;
      unawaited(settings.save());
    },
    refreshTimelineRows: refreshTimelineRows,
    onRowResizePointerDown: (rowIndex, event) {
      activeResizePointerState.value = event.pointer;
      isDraggingOnFixedRowState.value = true;
    },
    onRowResizePointerMove: (rowIndex, event) {
      if (activeResizePointerState.value != event.pointer) {
        return;
      }
      viewStateState.value = viewStateState.value.resizeRow(
        rowIndex: rowIndex,
        delta: event.delta.dy,
        minHeight: layoutConfig.rowMinHeight,
        maxHeight: layoutConfig.rowMaxHeight,
      );
    },
    onRowResizePointerUp: (event) {
      if (activeResizePointerState.value != event.pointer) {
        return;
      }
      activeResizePointerState.value = null;
      isDraggingOnFixedRowState.value = false;
    },
  );
}
