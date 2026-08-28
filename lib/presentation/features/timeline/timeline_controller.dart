import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
  final void Function(int rowIndex, PointerDownEvent event)
  onRowResizePointerDown;
  final void Function(int rowIndex, PointerMoveEvent event)
  onRowResizePointerMove;
  final void Function(PointerEvent event) onRowResizePointerUp;

  List<double> get rowHeights => viewState.rowHeights;
  List<int> get visibleYears => viewState.visibleYears;

  int yearFromColumnIndex(int columnIndex) {
    return viewState.yearFromColumnIndex(columnIndex);
  }
}

TimelineController useTimelineController({
  required BuildContext context,
  required int baseYear,
  required int totalDataRows,
  required List<double> initialRowHeights,
  required TimelineLayoutConfig layoutConfig,
  int? initialFocusYear,
}) {
  final viewStateState = useState(
    TimelineViewState.initial(
      baseYear: baseYear,
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
  _useInitialYearFocus(
    context: context,
    rowScrollControllers: rowScrollControllers,
    visibleYears: viewState.visibleYears,
    focusYear: initialFocusYear ?? baseYear,
    layoutConfig: layoutConfig,
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

void _useInitialYearFocus({
  required BuildContext context,
  required List<ScrollController> rowScrollControllers,
  required List<int> visibleYears,
  required int focusYear,
  required TimelineLayoutConfig layoutConfig,
}) {
  final hasAppliedInitialFocus = useRef(false);
  final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;

  useEffect(() {
    if (!isCurrentRoute || hasAppliedInitialFocus.value) {
      return null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || hasAppliedInitialFocus.value) {
        return;
      }
      hasAppliedInitialFocus.value = _tryScrollToYear(
        rowScrollControllers: rowScrollControllers,
        visibleYears: visibleYears,
        focusYear: focusYear,
        layoutConfig: layoutConfig,
      );
    });
    return null;
  }, [rowScrollControllers, isCurrentRoute, focusYear]);
}

bool _tryScrollToYear({
  required List<ScrollController> rowScrollControllers,
  required List<int> visibleYears,
  required int focusYear,
  required TimelineLayoutConfig layoutConfig,
}) {
  if (rowScrollControllers.isEmpty) {
    return false;
  }

  final primaryController = rowScrollControllers.first;
  if (!primaryController.hasClients ||
      !primaryController.position.hasViewportDimension) {
    return false;
  }

  final focusYearIndex = _resolveFocusYearIndex(
    visibleYears: visibleYears,
    focusYear: focusYear,
  );
  if (focusYearIndex == null) {
    return false;
  }

  final focusYearCenter =
      layoutConfig.buttonColumnWidth +
      ((focusYearIndex + 0.5) * layoutConfig.yearColumnWidth);
  final viewportWidth = primaryController.position.viewportDimension;
  final maxExtent = primaryController.position.maxScrollExtent;
  final targetOffset = (focusYearCenter - (viewportWidth / 2)).clamp(
    0.0,
    maxExtent,
  );

  primaryController.animateTo(
    targetOffset,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
  return true;
}

int? _resolveFocusYearIndex({
  required List<int> visibleYears,
  required int focusYear,
}) {
  if (visibleYears.isEmpty) {
    return null;
  }
  if (focusYear <= visibleYears.first) {
    return 0;
  }
  if (focusYear >= visibleYears.last) {
    return visibleYears.length - 1;
  }
  return visibleYears.indexOf(focusYear);
}
