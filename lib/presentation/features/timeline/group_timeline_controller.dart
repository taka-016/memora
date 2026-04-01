import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';
import 'package:memora/application/usecases/group/delete_group_event_usecase.dart';
import 'package:memora/application/usecases/group/get_group_events_usecase.dart';
import 'package:memora/application/usecases/group/save_group_event_usecase.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/presentation/features/timeline/group_timeline_view_state.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';

class GroupTimelineController {
  GroupTimelineController({
    required this.viewState,
    required this.displaySettings,
    required this.isDraggingOnFixedRow,
    required this.tripsByYear,
    required this.dvcPointUsagesByYear,
    required this.groupEventsByYear,
    required this.rowScrollControllers,
    required this.showMorePast,
    required this.showMoreFuture,
    required this.updateDisplaySettings,
    required this.refreshTimelineData,
    required this.onRowResizePointerDown,
    required this.onRowResizePointerMove,
    required this.onRowResizePointerUp,
    required this.buildMemberLabels,
    required this.saveGroupEvent,
  });

  final GroupTimelineViewState viewState;
  final TimelineDisplaySettings displaySettings;
  final bool isDraggingOnFixedRow;
  final Map<int, List<TripEntryDto>> tripsByYear;
  final Map<int, List<DvcPointUsageDto>> dvcPointUsagesByYear;
  final Map<int, GroupEventDto> groupEventsByYear;
  final List<ScrollController> rowScrollControllers;
  final VoidCallback showMorePast;
  final VoidCallback showMoreFuture;
  final void Function(TimelineDisplaySettings settings) updateDisplaySettings;
  final Future<void> Function() refreshTimelineData;
  final void Function(int rowIndex, PointerDownEvent event)
  onRowResizePointerDown;
  final void Function(int rowIndex, PointerMoveEvent event)
  onRowResizePointerMove;
  final void Function(PointerEvent event) onRowResizePointerUp;
  final List<String> Function({
    required DateTime? birthday,
    required String? gender,
    required int targetYear,
  })
  buildMemberLabels;
  final Future<void> Function({
    required GroupEventDto? currentEvent,
    required String groupId,
    required int selectedYear,
    required String memo,
  })
  saveGroupEvent;

  List<double> get rowHeights => viewState.rowHeights;
  List<int> get visibleYears => viewState.visibleYears;

  int yearFromColumnIndex(int columnIndex) {
    return viewState.yearFromColumnIndex(columnIndex);
  }
}

GroupTimelineController useGroupTimelineController({
  required BuildContext context,
  required WidgetRef ref,
  required GroupDto groupWithMembers,
  required int totalDataRows,
  required int initialYearRange,
  required int yearRangeIncrement,
  required double dataRowHeight,
  required double rowMinHeight,
  required double rowMaxHeight,
  required double buttonColumnWidth,
  required double yearColumnWidth,
  required void Function(RefreshTimelineCallback)? onSetRefreshCallback,
}) {
  final getTripEntriesUsecase = ref.read(getTripEntriesUsecaseProvider);
  final calculateSchoolGradeUsecase = ref.read(
    calculateSchoolGradeUsecaseProvider,
  );
  final calculateYakudoshiUsecase = ref.read(calculateYakudoshiUsecaseProvider);
  final getDvcPointUsagesUsecase = ref.read(getDvcPointUsagesUsecaseProvider);
  final getGroupEventsUsecase = ref.read(getGroupEventsUsecaseProvider);
  final saveGroupEventUsecase = ref.read(saveGroupEventUsecaseProvider);
  final deleteGroupEventUsecase = ref.read(deleteGroupEventUsecaseProvider);

  final viewStateState = useState(
    GroupTimelineViewState.initial(
      baseYear: DateTime.now().year,
      totalDataRows: totalDataRows,
      initialYearRange: initialYearRange,
      dataRowHeight: dataRowHeight,
    ),
  );
  final isDraggingOnFixedRowState = useState(false);
  final tripsByYearState = useState<Map<int, List<TripEntryDto>>>({});
  final dvcPointUsagesByYearState = useState<Map<int, List<DvcPointUsageDto>>>(
    {},
  );
  final groupEventsByYearState = useState<Map<int, GroupEventDto>>({});
  final activeResizePointerState = useState<int?>(null);
  final displaySettingsState = useState(TimelineDisplaySettings.defaults);
  final rowScrollControllers = useMemoized(
    () => List.generate(totalDataRows + 1, (_) => ScrollController()),
    [totalDataRows],
  );
  final isSyncingRef = useRef(false);
  final loadingTripYearsRef = useRef<Map<int, Future<void>>>({});
  final viewState = viewStateState.value;

  useEffect(() {
    Future.microtask(() async {
      final loaded = await TimelineDisplaySettings.load();
      if (!context.mounted) return;
      displaySettingsState.value = loaded;
    });
    return null;
  }, []);

  useEffect(() {
    viewStateState.value = viewStateState.value.ensureRowCount(
      totalDataRows: totalDataRows,
      dataRowHeight: dataRowHeight,
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

  Future<void> loadTripDataForYear(int year) async {
    if (tripsByYearState.value.containsKey(year)) {
      return;
    }

    final inFlightFuture = loadingTripYearsRef.value[year];
    if (inFlightFuture != null) {
      await inFlightFuture;
      return;
    }

    final loadFuture = () async {
      try {
        final trips = await getTripEntriesUsecase.execute(
          groupWithMembers.id,
          year,
        );

        if (!context.mounted) {
          return;
        }

        tripsByYearState.value = {...tripsByYearState.value, year: trips};
      } catch (e, stack) {
        logger.e(
          'GroupTimelineController.loadTripDataForYear: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );

        if (!context.mounted) {
          return;
        }

        tripsByYearState.value = {...tripsByYearState.value, year: const []};
      } finally {
        loadingTripYearsRef.value = {...loadingTripYearsRef.value}
          ..remove(year);
      }
    }();

    loadingTripYearsRef.value = {
      ...loadingTripYearsRef.value,
      year: loadFuture,
    };
    await loadFuture;
  }

  Future<void> loadTripDataForVisibleYears() async {
    for (final year in viewStateState.value.visibleYears) {
      await loadTripDataForYear(year);
    }
  }

  Future<void> loadDvcPointUsageData() async {
    try {
      final usages = await getDvcPointUsagesUsecase.execute(
        groupWithMembers.id,
      );

      if (!context.mounted) {
        return;
      }

      dvcPointUsagesByYearState.value = _groupDvcPointUsagesByYear(usages);
    } catch (e, stack) {
      logger.e(
        'GroupTimelineController.loadDvcPointUsageData: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );

      if (!context.mounted) {
        return;
      }

      dvcPointUsagesByYearState.value = {};
    }
  }

  Future<void> loadGroupEventData() async {
    try {
      final events = await getGroupEventsUsecase.execute(groupWithMembers.id);

      if (!context.mounted) {
        return;
      }

      groupEventsByYearState.value = {
        for (final event in events) event.year: event,
      };
    } catch (e, stack) {
      logger.e(
        'GroupTimelineController.loadGroupEventData: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );

      if (!context.mounted) {
        return;
      }

      groupEventsByYearState.value = {};
    }
  }

  Future<void> refreshTimelineData() async {
    tripsByYearState.value = {};
    dvcPointUsagesByYearState.value = {};
    groupEventsByYearState.value = {};
    await Future.wait([
      loadTripDataForVisibleYears(),
      loadDvcPointUsageData(),
      loadGroupEventData(),
    ]);
  }

  useEffect(() {
    Future.microtask(loadTripDataForVisibleYears);
    return null;
  }, [viewState.startYearOffset, viewState.endYearOffset, groupWithMembers.id]);

  useEffect(() {
    Future.microtask(loadDvcPointUsageData);
    return null;
  }, [groupWithMembers.id]);

  useEffect(() {
    Future.microtask(loadGroupEventData);
    return null;
  }, [groupWithMembers.id]);

  useEffect(
    () {
      if (onSetRefreshCallback != null) {
        onSetRefreshCallback(refreshTimelineData);
      }
      return null;
    },
    [
      onSetRefreshCallback,
      groupWithMembers.id,
      viewState.startYearOffset,
      viewState.endYearOffset,
    ],
  );

  void scrollToCurrentYear() {
    if (rowScrollControllers.isEmpty) {
      return;
    }

    final primaryController = rowScrollControllers.first;
    if (!primaryController.hasClients) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final viewportWidth = renderBox.size.width;
    final totalWidth =
        (2 * buttonColumnWidth) +
        (viewState.visibleYears.length * yearColumnWidth);
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

  List<String> buildMemberLabels({
    required DateTime? birthday,
    required String? gender,
    required int targetYear,
  }) {
    final displaySettings = displaySettingsState.value;
    final labels = <String>[
      if (displaySettings.showAge) ...?_buildAgeLabel(birthday, targetYear),
      if (displaySettings.showGrade)
        ...?_buildOptionalLabel(
          calculateSchoolGradeUsecase.execute(birthday, targetYear),
        ),
      if (displaySettings.showYakudoshi)
        ...?_buildOptionalLabel(
          calculateYakudoshiUsecase.execute(birthday, gender, targetYear),
        ),
    ];

    return labels;
  }

  Future<void> saveGroupEvent({
    required GroupEventDto? currentEvent,
    required String groupId,
    required int selectedYear,
    required String memo,
  }) async {
    if (memo.isEmpty) {
      if (currentEvent != null) {
        await deleteGroupEventUsecase.execute(currentEvent.id);
      }
      final updated = Map<int, GroupEventDto>.from(
        groupEventsByYearState.value,
      );
      updated.remove(selectedYear);
      groupEventsByYearState.value = updated;
      return;
    }

    final savedEvent = await saveGroupEventUsecase.execute(
      GroupEventDto(
        id: currentEvent?.id ?? '',
        groupId: groupId,
        year: selectedYear,
        memo: memo,
      ),
    );
    groupEventsByYearState.value = {
      ...groupEventsByYearState.value,
      selectedYear: savedEvent,
    };
  }

  return GroupTimelineController(
    viewState: viewState,
    displaySettings: displaySettingsState.value,
    isDraggingOnFixedRow: isDraggingOnFixedRowState.value,
    tripsByYear: tripsByYearState.value,
    dvcPointUsagesByYear: dvcPointUsagesByYearState.value,
    groupEventsByYear: groupEventsByYearState.value,
    rowScrollControllers: rowScrollControllers,
    showMorePast: () {
      viewStateState.value = viewStateState.value.expandPast(
        yearRangeIncrement,
      );
    },
    showMoreFuture: () {
      viewStateState.value = viewStateState.value.expandFuture(
        yearRangeIncrement,
      );
    },
    updateDisplaySettings: (settings) {
      displaySettingsState.value = settings;
      unawaited(settings.save());
    },
    refreshTimelineData: refreshTimelineData,
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
        minHeight: rowMinHeight,
        maxHeight: rowMaxHeight,
      );
    },
    onRowResizePointerUp: (event) {
      if (activeResizePointerState.value != event.pointer) {
        return;
      }
      activeResizePointerState.value = null;
      isDraggingOnFixedRowState.value = false;
    },
    buildMemberLabels: buildMemberLabels,
    saveGroupEvent: saveGroupEvent,
  );
}

Map<int, List<DvcPointUsageDto>> _groupDvcPointUsagesByYear(
  List<DvcPointUsageDto> usages,
) {
  final grouped = <int, List<DvcPointUsageDto>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.usageYearMonth.year, () => []).add(usage);
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) {
      final comparedMonth = a.usageYearMonth.compareTo(b.usageYearMonth);
      if (comparedMonth != 0) {
        return comparedMonth;
      }
      return a.id.compareTo(b.id);
    });
  }

  return grouped;
}

List<String>? _buildAgeLabel(DateTime? birthday, int targetYear) {
  if (birthday == null) {
    return null;
  }

  final age = targetYear - birthday.year;
  if (age < 0) {
    return null;
  }

  return ['$age歳'];
}

List<String>? _buildOptionalLabel(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return [value];
}
