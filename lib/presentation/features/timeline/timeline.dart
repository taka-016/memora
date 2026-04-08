import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/formatters/japanese_era_formatter.dart';
import 'package:memora/presentation/features/dvc/dvc_point_usage_detail_modal.dart';
import 'package:memora/presentation/features/group/group_event_edit_modal.dart';
import 'package:memora/presentation/features/timeline/dvc_cell.dart';
import 'package:memora/presentation/features/timeline/group_event_cell.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class Timeline extends HookConsumerWidget {
  const Timeline({
    super.key,
    required this.groupWithMembers,
    this.onBackPressed,
    this.onTripManagementSelected,
    this.onDvcPointCalculationPressed,
    this.onSetRefreshCallback,
  });

  static const TimelineLayoutConfig _layoutConfig =
      TimelineLayoutConfig.defaults;

  final GroupDto groupWithMembers;
  final VoidCallback? onBackPressed;
  final Function(String groupId, int year)? onTripManagementSelected;
  final VoidCallback? onDvcPointCalculationPressed;
  final void Function(RefreshTimelineCallback)? onSetRefreshCallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDataRows = 3 + groupWithMembers.members.length;
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final dataTableKey = useMemoized(() => GlobalKey(), []);
    final timelineController = useTimelineController(
      context: context,
      ref: ref,
      groupWithMembers: groupWithMembers,
      totalDataRows: totalDataRows,
      layoutConfig: _layoutConfig,
      onSetRefreshCallback: onSetRefreshCallback,
    );

    void showDisplaySettingsSheet() {
      var localSettings = timelineController.displaySettings;
      showModalBottomSheet<void>(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: TimelineDisplaySettings.definitions.map((
                    definition,
                  ) {
                    return SwitchListTile(
                      key: Key(definition.toggleKey),
                      title: Text(definition.label),
                      value: definition.getValue(localSettings),
                      onChanged: (value) {
                        final updatedSettings = definition.update(
                          localSettings,
                          value,
                        );
                        setState(() {
                          localSettings = updatedSettings;
                        });
                        timelineController.updateDisplaySettings(
                          updatedSettings,
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      );
    }

    void onTripCellTapped(int columnIndex) {
      if (onTripManagementSelected == null) {
        return;
      }
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      onTripManagementSelected!(groupWithMembers.id, selectedYear);
    }

    void showDvcPointUsageDetailsDialog(int columnIndex) {
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      final usages =
          timelineController.dvcPointUsagesByYear[selectedYear] ?? [];

      if (usages.isEmpty) {
        return;
      }

      showDvcPointUsageDetailModal(
        context: context,
        selectedYear: selectedYear,
        usages: usages,
      );
    }

    Widget buildTripCellContent(int columnIndex) {
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      final trips = timelineController.tripsByYear[selectedYear] ?? [];

      return TripCell(
        trips: trips,
        availableHeight: timelineController.rowHeights[0],
        availableWidth: _layoutConfig.yearColumnWidth,
      );
    }

    Widget buildDvcPointUsageCellContent(int columnIndex) {
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      final usages =
          timelineController.dvcPointUsagesByYear[selectedYear] ?? [];

      if (usages.isEmpty) {
        return const SizedBox.shrink();
      }

      return DvcCell(
        usages: usages,
        availableHeight: timelineController.rowHeights[2],
        availableWidth: _layoutConfig.yearColumnWidth,
      );
    }

    Widget buildGroupEventCellContent(int columnIndex) {
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      final event = timelineController.groupEventsByYear[selectedYear];
      if (event == null) {
        return const SizedBox.shrink();
      }

      return GroupEventCell(
        memo: event.memo,
        availableHeight: timelineController.rowHeights[1],
        availableWidth: _layoutConfig.yearColumnWidth,
      );
    }

    Future<void> showGroupEventEditDialog(int columnIndex) async {
      final selectedYear = timelineController.yearFromColumnIndex(columnIndex);
      final currentEvent = timelineController.groupEventsByYear[selectedYear];

      await showGroupEventEditModal(
        context: context,
        selectedYear: selectedYear,
        initialMemo: currentEvent?.memo ?? '',
        onSave: (memo) async {
          await timelineController.saveGroupEvent(
            currentEvent: currentEvent,
            groupId: groupWithMembers.id,
            selectedYear: selectedYear,
            memo: memo,
          );
        },
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
      final targetYear = timelineController.yearFromColumnIndex(columnIndex);
      final lines = timelineController.buildMemberLabels(
        birthday: member.birthday,
        gender: member.gender,
        targetYear: targetYear,
      );

      if (lines.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 4),
        child: Text(lines.join('\n')),
      );
    }

    Widget buildScrollableDataCells(int rowIndex) {
      final columnCount = 2 + timelineController.visibleYears.length;

      return Row(
        children: List.generate(columnCount, (columnIndex) {
          final width = columnIndex == 0 || columnIndex == columnCount - 1
              ? _layoutConfig.buttonColumnWidth
              : _layoutConfig.yearColumnWidth;

          final isTripRow = rowIndex == 0;
          final isGroupEventRow = rowIndex == 1;
          final isDvcPointUsageRow = rowIndex == 2;
          final isYearColumn =
              columnIndex != 0 && columnIndex != columnCount - 1;
          final year = timelineController.yearFromColumnIndex(columnIndex);
          final cellKey = isDvcPointUsageRow && isYearColumn
              ? Key('dvc_point_usage_cell_$year')
              : isGroupEventRow && isYearColumn
              ? Key('group_event_cell_$year')
              : null;

          return SizedBox(
            width: width,
            height: timelineController.rowHeights[rowIndex],
            child: GestureDetector(
              onTap: isTripRow && isYearColumn
                  ? () => onTripCellTapped(columnIndex)
                  : isGroupEventRow && isYearColumn
                  ? () => showGroupEventEditDialog(columnIndex)
                  : isDvcPointUsageRow && isYearColumn
                  ? () => showDvcPointUsageDetailsDialog(columnIndex)
                  : null,
              child: Container(
                key: cellKey,
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: _layoutConfig.borderWidth,
                    ),
                    right: BorderSide(
                      color: borderColor,
                      width: _layoutConfig.borderWidth,
                    ),
                  ),
                  color: isTripRow || isGroupEventRow || isDvcPointUsageRow
                      ? Colors.lightBlue.shade50
                      : Colors.transparent,
                ),
                child: isTripRow && isYearColumn
                    ? buildTripCellContent(columnIndex)
                    : isGroupEventRow && isYearColumn
                    ? buildGroupEventCellContent(columnIndex)
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('fixed_row_$rowIndex'),
                  onTap: rowIndex == 2 ? onDvcPointCalculationPressed : null,
                  child: Container(
                    width: _layoutConfig.fixedColumnWidth,
                    height: timelineController.rowHeights[rowIndex],
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: borderColor,
                          width: _layoutConfig.borderWidth,
                        ),
                        bottom: BorderSide(
                          color: borderColor,
                          width: _layoutConfig.borderWidth,
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
              ),
              Container(
                width: _layoutConfig.borderWidth,
                height: timelineController.rowHeights[rowIndex],
                color: borderColor,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller:
                      timelineController.rowScrollControllers[rowIndex + 1],
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    key: Key('scrollable_row_$rowIndex'),
                    height: timelineController.rowHeights[rowIndex],
                    child: buildScrollableDataCells(rowIndex),
                  ),
                ),
              ),
            ],
          ),
          if (rowIndex < timelineController.rowHeights.length)
            Positioned(
              left: 0,
              bottom: -19,
              child: Listener(
                key: Key('row_resizer_icon_$rowIndex'),
                onPointerDown: (event) =>
                    timelineController.onRowResizePointerDown(rowIndex, event),
                onPointerMove: (event) =>
                    timelineController.onRowResizePointerMove(rowIndex, event),
                onPointerUp: timelineController.onRowResizePointerUp,
                onPointerCancel: timelineController.onRowResizePointerUp,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    width: _layoutConfig.fixedColumnWidth,
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
      final cells = <Widget>[];

      cells.add(
        Container(
          width: _layoutConfig.buttonColumnWidth,
          height: _layoutConfig.headerRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
              bottom: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
              right: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
            ),
          ),
          child: TextButton(
            key: const Key('show_more_past'),
            onPressed: timelineController.showMorePast,
            child: const Text('さらに表示'),
          ),
        ),
      );

      for (final year in timelineController.visibleYears) {
        final eraFormatted =
            JapaneseEraFormatter.formatJapaneseEraFormatterYear(year);
        final combinedYearFormat = '$year年($eraFormatted)';
        cells.add(
          Container(
            width: _layoutConfig.yearColumnWidth,
            height: _layoutConfig.headerRowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: _layoutConfig.borderWidth,
                ),
                bottom: BorderSide(
                  color: borderColor,
                  width: _layoutConfig.borderWidth,
                ),
                right: BorderSide(
                  color: borderColor,
                  width: _layoutConfig.borderWidth,
                ),
              ),
            ),
            child: Text(combinedYearFormat),
          ),
        );
      }

      cells.add(
        Container(
          width: _layoutConfig.buttonColumnWidth,
          height: _layoutConfig.headerRowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
              bottom: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
              right: BorderSide(
                color: borderColor,
                width: _layoutConfig.borderWidth,
              ),
            ),
          ),
          child: TextButton(
            key: const Key('show_more_future'),
            onPressed: timelineController.showMoreFuture,
            child: const Text('さらに表示'),
          ),
        ),
      );

      return Row(children: cells);
    }

    Widget buildScrollableHeaderRow() {
      return SingleChildScrollView(
        controller: timelineController.rowScrollControllers[0],
        scrollDirection: Axis.horizontal,
        child: Container(key: dataTableKey, child: buildHeaderRow()),
      );
    }

    Widget buildFixedHeaderCell() {
      return Container(
        width: _layoutConfig.fixedColumnWidth,
        height: _layoutConfig.headerRowHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: _layoutConfig.borderWidth,
            ),
            top: BorderSide(
              color: borderColor,
              width: _layoutConfig.borderWidth,
            ),
            bottom: BorderSide(
              color: borderColor,
              width: _layoutConfig.borderWidth,
            ),
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
                  width: _layoutConfig.borderWidth,
                  height: _layoutConfig.headerRowHeight,
                  color: borderColor,
                ),
                Expanded(child: buildScrollableHeaderRow()),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: timelineController.isDraggingOnFixedRow
                    ? const NeverScrollableScrollPhysics()
                    : null,
                child: Column(
                  children: [
                    ...buildDataRowsWithResizers(),
                    SizedBox(height: _layoutConfig.resizeBottomMargin),
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

  Widget _buildDvcPointUsageLabel({required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DVC'),
          const SizedBox(width: 8),
          InkWell(
            key: const Key('timeline_dvc_point_usage_edit_button'),
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.edit, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
