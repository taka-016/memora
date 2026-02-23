import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/formatters/japanese_era_formatter.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class GroupTimeline extends HookConsumerWidget {
  final GroupDto groupWithMembers;
  final VoidCallback? onBackPressed;
  final Function(String groupId, int year)? onTripManagementSelected;
  final VoidCallback? onDvcPointCalculationPressed;
  final Function(VoidCallback)? onSetRefreshCallback;

  static const int _initialYearRange = 5;
  static const int _yearRangeIncrement = 5;

  static const double _dataRowHeight = 100.0;
  static const double _headerRowHeight = 56.0;
  static const double _borderWidth = 1.0;

  static const double _fixedColumnWidth = 100.0;
  static const double _buttonColumnWidth = 100.0;
  static const double _yearColumnWidth = 120.0;

  static const double _resizeBottomMargin = 100.0;
  static const double _rowMinHeight = 100.0;
  static const double _rowMaxHeight = 500.0;

  const GroupTimeline({
    super.key,
    required this.groupWithMembers,
    this.onBackPressed,
    this.onTripManagementSelected,
    this.onDvcPointCalculationPressed,
    this.onSetRefreshCallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getTripEntriesUsecase = ref.read(getTripEntriesUsecaseProvider);
    final calculateSchoolGradeUsecase = ref.read(
      calculateSchoolGradeUsecaseProvider,
    );
    final calculateYakudoshiUsecase = ref.read(
      calculateYakudoshiUsecaseProvider,
    );
    final dvcPointUsageQueryService = ref.read(
      dvcPointUsageQueryServiceProvider,
    );
    final totalDataRows = 3 + groupWithMembers.members.length;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    final startYearOffset = useState(-_initialYearRange);
    final endYearOffset = useState(_initialYearRange);
    final isDraggingOnFixedRow = useState(false);
    final tripsByYearState = useState<Map<int, List<TripEntryDto>>>({});
    final dvcPointUsagesByYearState =
        useState<Map<int, List<DvcPointUsageDto>>>({});
    final rowHeightsState = useState<List<double>>(
      List.filled(totalDataRows, _dataRowHeight),
    );
    final activeResizePointer = useState<int?>(null);
    final displaySettingsState = useState(TimelineDisplaySettings.defaults);
    final dataTableKey = useMemoized(() => GlobalKey(), []);
    final rowScrollControllers = useMemoized(
      () => List.generate(totalDataRows + 1, (_) => ScrollController()),
      [totalDataRows],
    );
    final isSyncingRef = useRef(false);

    useEffect(() {
      Future.microtask(() async {
        final loaded = await TimelineDisplaySettings.load();
        if (!context.mounted) return;
        displaySettingsState.value = loaded;
      });
      return null;
    }, []);

    useEffect(() {
      final current = rowHeightsState.value;
      if (current.length != totalDataRows) {
        final updated = List<double>.generate(
          totalDataRows,
          (index) => index < current.length ? current[index] : _dataRowHeight,
        );
        rowHeightsState.value = updated;
      }
      return null;
    }, [totalDataRows]);

    final rowHeights = rowHeightsState.value;
    final displaySettings = displaySettingsState.value;

    void updateDisplaySettings(TimelineDisplaySettings settings) {
      displaySettingsState.value = settings;
      unawaited(settings.save());
    }

    void showDisplaySettingsSheet() {
      var localSettings = displaySettingsState.value;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      key: const Key('toggle_show_age'),
                      title: const Text('年齢を表示'),
                      value: localSettings.showAge,
                      onChanged: (value) {
                        setState(() {
                          localSettings = localSettings.copyWith(
                            showAge: value,
                          );
                        });
                        updateDisplaySettings(localSettings);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('toggle_show_grade'),
                      title: const Text('学年を表示'),
                      value: localSettings.showGrade,
                      onChanged: (value) {
                        setState(() {
                          localSettings = localSettings.copyWith(
                            showGrade: value,
                          );
                        });
                        updateDisplaySettings(localSettings);
                      },
                    ),
                    SwitchListTile(
                      key: const Key('toggle_show_yakudoshi'),
                      title: const Text('厄年を表示'),
                      value: localSettings.showYakudoshi,
                      onChanged: (value) {
                        setState(() {
                          localSettings = localSettings.copyWith(
                            showYakudoshi: value,
                          );
                        });
                        updateDisplaySettings(localSettings);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    void syncScrollControllers(int sourceIndex) {
      if (isSyncingRef.value) return;

      final sourceController = rowScrollControllers[sourceIndex];
      if (!sourceController.hasClients) return;

      isSyncingRef.value = true;
      final targetOffset = sourceController.offset;

      for (int i = 0; i < rowScrollControllers.length; i++) {
        if (i == sourceIndex) continue;
        final controller = rowScrollControllers[i];
        if (controller.hasClients) {
          controller.jumpTo(targetOffset);
        }
      }

      isSyncingRef.value = false;
    }

    useEffect(() {
      final listeners = <VoidCallback>[];
      for (int i = 0; i < rowScrollControllers.length; i++) {
        final controller = rowScrollControllers[i];
        void listener() => syncScrollControllers(i);
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

      try {
        final trips = await getTripEntriesUsecase.execute(
          groupWithMembers.id,
          year,
        );

        if (!context.mounted) return;

        final updated = Map<int, List<TripEntryDto>>.from(
          tripsByYearState.value,
        );
        updated[year] = trips;
        tripsByYearState.value = updated;
      } catch (e, stack) {
        logger.e(
          'GroupTimeline._loadTripDataForYear: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );

        if (!context.mounted) return;

        final updated = Map<int, List<TripEntryDto>>.from(
          tripsByYearState.value,
        );
        updated[year] = [];
        tripsByYearState.value = updated;
      }
    }

    Future<void> loadTripDataForVisibleYears() async {
      final currentYear = DateTime.now().year;
      for (
        int offset = startYearOffset.value;
        offset <= endYearOffset.value;
        offset++
      ) {
        final year = currentYear + offset;
        await loadTripDataForYear(year);
      }
    }

    Future<void> loadDvcPointUsageData() async {
      try {
        final usages = await dvcPointUsageQueryService
            .getDvcPointUsagesByGroupId(groupWithMembers.id);

        if (!context.mounted) return;

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

        dvcPointUsagesByYearState.value = grouped;
      } catch (e, stack) {
        logger.e(
          'GroupTimeline.loadDvcPointUsageData: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );

        if (!context.mounted) return;
        dvcPointUsagesByYearState.value = {};
      }
    }

    Future<void> refreshTimelineData() async {
      tripsByYearState.value = {};
      dvcPointUsagesByYearState.value = {};
      await Future.wait([
        loadTripDataForVisibleYears(),
        loadDvcPointUsageData(),
      ]);
    }

    useEffect(() {
      Future.microtask(loadTripDataForVisibleYears);
      return null;
    }, [startYearOffset.value, endYearOffset.value, groupWithMembers.id]);

    useEffect(() {
      Future.microtask(loadDvcPointUsageData);
      return null;
    }, [groupWithMembers.id]);

    useEffect(() {
      if (onSetRefreshCallback != null) {
        onSetRefreshCallback!(refreshTimelineData);
      }
      return null;
    }, [onSetRefreshCallback]);

    void scrollToCurrentYear() {
      if (rowScrollControllers.isEmpty) return;

      final primaryController = rowScrollControllers.first;
      if (!primaryController.hasClients) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final viewportWidth = renderBox.size.width;
      final yearColumnsCount = endYearOffset.value - startYearOffset.value + 2;
      final totalWidth =
          2 * _buttonColumnWidth + yearColumnsCount * _yearColumnWidth;
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
        if (!context.mounted) return;
        scrollToCurrentYear();
      });
      return null;
    }, [rowScrollControllers]);

    void showMorePast() {
      startYearOffset.value = startYearOffset.value - _yearRangeIncrement;
    }

    void showMoreFuture() {
      endYearOffset.value = endYearOffset.value + _yearRangeIncrement;
    }

    void onTripCellTapped(int columnIndex) {
      if (onTripManagementSelected == null) {
        return;
      }
      final selectedYear = _yearFromColumnIndex(
        columnIndex,
        startYearOffset.value,
      );
      onTripManagementSelected!(groupWithMembers.id, selectedYear);
    }

    Widget buildTripCellContent(int columnIndex) {
      final selectedYear = _yearFromColumnIndex(
        columnIndex,
        startYearOffset.value,
      );
      final trips = tripsByYearState.value[selectedYear] ?? [];

      return TripCell(
        trips: trips,
        availableHeight: rowHeights[0],
        availableWidth: _yearColumnWidth,
      );
    }

    Widget buildDvcPointUsageCellContent(int columnIndex) {
      final selectedYear = _yearFromColumnIndex(
        columnIndex,
        startYearOffset.value,
      );
      final usages = dvcPointUsagesByYearState.value[selectedYear] ?? [];

      if (usages.isEmpty) {
        return const SizedBox.shrink();
      }

      final usageText = usages
          .map(
            (usage) =>
                '${dvcFormatYearMonth(usage.usageYearMonth)}\n${usage.usedPoint}pt\n${usage.memo ?? ''}',
          )
          .join('\n\n');

      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 4, right: 8),
        child: Text(usageText),
      );
    }

    bool isMemberRow(int rowIndex) => rowIndex >= 3;

    Widget buildMemberCellContent(int rowIndex, int columnIndex) {
      if (!isMemberRow(rowIndex)) {
        return const SizedBox.shrink();
      }

      final memberIndex = rowIndex - 3;
      if (memberIndex >= groupWithMembers.members.length) {
        return const SizedBox.shrink();
      }

      final member = groupWithMembers.members[memberIndex];
      final birthday = member.birthday;

      final targetYear = _yearFromColumnIndex(
        columnIndex,
        startYearOffset.value,
      );
      final ageLabel = displaySettings.showAge
          ? _buildAgeLabel(birthday, targetYear)
          : null;
      final gradeLabel = displaySettings.showGrade
          ? calculateSchoolGradeUsecase.execute(birthday, targetYear)
          : null;
      final yakudoshiLabel = displaySettings.showYakudoshi
          ? calculateYakudoshiUsecase.execute(
              birthday,
              member.gender,
              targetYear,
            )
          : null;

      if (ageLabel == null && gradeLabel == null && yakudoshiLabel == null) {
        return const SizedBox.shrink();
      }

      final lines = <String?>[ageLabel, gradeLabel, yakudoshiLabel]
          .where((label) => label != null && label.isNotEmpty)
          .cast<String>()
          .toList();

      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 4),
        child: Text(lines.join('\n')),
      );
    }

    Widget buildScrollableDataCells(int rowIndex) {
      final columnCount = 2 + (endYearOffset.value - startYearOffset.value + 1);

      return Row(
        children: List.generate(columnCount, (columnIndex) {
          final width = columnIndex == 0 || columnIndex == columnCount - 1
              ? _buttonColumnWidth
              : _yearColumnWidth;

          final isTripRow = rowIndex == 0;
          final isGroupEventRow = rowIndex == 1;
          final isDvcPointUsageRow = rowIndex == 2;
          final isYearColumn =
              columnIndex != 0 && columnIndex != columnCount - 1;
          final year = _yearFromColumnIndex(columnIndex, startYearOffset.value);
          final cellKey = isDvcPointUsageRow && isYearColumn
              ? Key('dvc_point_usage_cell_$year')
              : null;

          return SizedBox(
            width: width,
            height: rowHeights[rowIndex],
            child: GestureDetector(
              onTap: isTripRow && isYearColumn
                  ? () => onTripCellTapped(columnIndex)
                  : null,
              child: Container(
                key: cellKey,
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: _borderWidth),
                    right: BorderSide(color: borderColor, width: _borderWidth),
                  ),
                  color: isTripRow || isGroupEventRow || isDvcPointUsageRow
                      ? Colors.lightBlue.shade50
                      : Colors.transparent,
                ),
                child: isTripRow && isYearColumn
                    ? buildTripCellContent(columnIndex)
                    : isDvcPointUsageRow && isYearColumn
                    ? buildDvcPointUsageCellContent(columnIndex)
                    : isYearColumn
                    ? buildMemberCellContent(rowIndex, columnIndex)
                    : const SizedBox.shrink(),
              ),
            ),
          );
        }),
      );
    }

    Widget buildDataRow(int rowIndex, String label) {
      final colorScheme = Theme.of(context).colorScheme;

      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: rowIndex == 2 ? onDvcPointCalculationPressed : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  key: Key('fixed_row_$rowIndex'),
                  width: _fixedColumnWidth,
                  height: rowHeights[rowIndex],
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: borderColor, width: _borderWidth),
                      bottom: BorderSide(
                        color: borderColor,
                        width: _borderWidth,
                      ),
                    ),
                  ),
                  child: rowIndex == 2
                      ? _buildDvcPointUsageLabel(
                          onPressed: onDvcPointCalculationPressed,
                        )
                      : Text(label),
                ),
              ),
              Container(
                width: _borderWidth,
                height: rowHeights[rowIndex],
                color: borderColor,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: rowScrollControllers[rowIndex + 1],
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    key: Key('scrollable_row_$rowIndex'),
                    height: rowHeights[rowIndex],
                    child: buildScrollableDataCells(rowIndex),
                  ),
                ),
              ),
            ],
          ),
          if (rowIndex < rowHeights.length)
            Positioned(
              left: 0,
              bottom: -19,
              child: Listener(
                key: Key('row_resizer_icon_$rowIndex'),
                onPointerDown: (event) {
                  activeResizePointer.value = event.pointer;
                  isDraggingOnFixedRow.value = true;
                },
                onPointerMove: (event) {
                  if (activeResizePointer.value != event.pointer) {
                    return;
                  }
                  final updatedHeights = List<double>.from(
                    rowHeightsState.value,
                  );
                  final newHeight = (updatedHeights[rowIndex] + event.delta.dy)
                      .clamp(_rowMinHeight, _rowMaxHeight);
                  updatedHeights[rowIndex] = newHeight;
                  rowHeightsState.value = updatedHeights;
                },
                onPointerUp: (event) {
                  if (activeResizePointer.value != event.pointer) {
                    return;
                  }
                  activeResizePointer.value = null;
                  isDraggingOnFixedRow.value = false;
                },
                onPointerCancel: (event) {
                  if (activeResizePointer.value != event.pointer) {
                    return;
                  }
                  activeResizePointer.value = null;
                  isDraggingOnFixedRow.value = false;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    width: _fixedColumnWidth,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(0, 255, 0, 0),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 40,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    List<Widget> buildDataRowsWithResizers() {
      final members = groupWithMembers.members;
      final dataRowLabels = [
        '旅行',
        'イベント',
        'DVC',
        ...members.map((m) => m.displayName),
      ];

      return List.generate(dataRowLabels.length, (index) {
        return buildDataRow(index, dataRowLabels[index]);
      });
    }

    Widget buildHeaderRow() {
      final currentYear = DateTime.now().year;
      List<Widget> cells = [];

      cells.add(
        Container(
          width: _buttonColumnWidth,
          height: _headerRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: _borderWidth),
              bottom: BorderSide(color: borderColor, width: _borderWidth),
              right: BorderSide(color: borderColor, width: _borderWidth),
            ),
          ),
          child: TextButton(
            key: const Key('show_more_past'),
            onPressed: showMorePast,
            child: const Text('さらに表示'),
          ),
        ),
      );

      for (int i = startYearOffset.value; i <= endYearOffset.value; i++) {
        final year = currentYear + i;
        final eraFormatted =
            JapaneseEraFormatter.formatJapaneseEraFormatterYear(year);
        final combinedYearFormat = '$year年($eraFormatted)';
        cells.add(
          Container(
            width: _yearColumnWidth,
            height: _headerRowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: _borderWidth),
                bottom: BorderSide(color: borderColor, width: _borderWidth),
                right: BorderSide(color: borderColor, width: _borderWidth),
              ),
            ),
            child: Text(combinedYearFormat),
          ),
        );
      }

      cells.add(
        Container(
          width: _buttonColumnWidth,
          height: _headerRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: borderColor, width: _borderWidth),
              bottom: BorderSide(color: borderColor, width: _borderWidth),
              right: BorderSide(color: borderColor, width: _borderWidth),
            ),
          ),
          child: TextButton(
            key: const Key('show_more_future'),
            onPressed: showMoreFuture,
            child: const Text('さらに表示'),
          ),
        ),
      );

      return Row(children: cells);
    }

    Widget buildScrollableHeaderRow() {
      return SingleChildScrollView(
        controller: rowScrollControllers[0],
        scrollDirection: Axis.horizontal,
        child: Container(key: dataTableKey, child: buildHeaderRow()),
      );
    }

    Widget buildFixedHeaderCell() {
      return Container(
        width: _fixedColumnWidth,
        height: _headerRowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: borderColor, width: _borderWidth),
            top: BorderSide(color: borderColor, width: _borderWidth),
            bottom: BorderSide(color: borderColor, width: _borderWidth),
          ),
        ),
      );
    }

    Widget buildBackButton() {
      return Positioned(
        left: 0,
        top: -4,
        child: IconButton(
          key: const Key('back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      );
    }

    Widget buildGroupTitle() {
      return Center(
        child: Text(
          groupWithMembers.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }

    Widget buildSettingsButton() {
      return Positioned(
        right: 0,
        top: -4,
        child: IconButton(
          key: const Key('timeline_settings_button'),
          icon: const Icon(Icons.settings_input_composite),
          onPressed: showDisplaySettingsSheet,
        ),
      );
    }

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                if (onBackPressed != null) buildBackButton(),
                buildGroupTitle(),
                buildSettingsButton(),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildTimelineTable() {
      return Container(
        key: const Key('unified_border_table'),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildFixedHeaderCell(),
                Container(
                  width: _borderWidth,
                  height: _headerRowHeight,
                  color: borderColor,
                ),
                Expanded(child: buildScrollableHeaderRow()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: isDraggingOnFixedRow.value
                    ? const NeverScrollableScrollPhysics()
                    : null,
                child: Column(
                  children: [
                    ...buildDataRowsWithResizers(),
                    SizedBox(height: _resizeBottomMargin),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const Key('group_timeline'),
      child: Column(
        children: [
          buildHeader(),
          Expanded(child: buildTimelineTable()),
        ],
      ),
    );
  }

  static int _yearFromColumnIndex(int columnIndex, int startYearOffset) {
    final yearIndex = columnIndex - 1;
    final currentYear = DateTime.now().year;
    return currentYear + startYearOffset + yearIndex;
  }

  Widget _buildDvcPointUsageLabel({required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DVC'),
          const SizedBox(width: 8),
          GestureDetector(
            key: const Key('timeline_dvc_point_usage_edit_button'),
            onTap: onPressed,
            child: const Icon(Icons.edit, size: 16),
          ),
        ],
      ),
    );
  }

  String? _buildAgeLabel(DateTime? birthday, int targetYear) {
    if (birthday == null) {
      return null;
    }

    final age = targetYear - birthday.year;
    if (age < 0) {
      return null;
    }

    return '$age歳';
  }
}
