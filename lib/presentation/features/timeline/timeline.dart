import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_dto.dart';
import 'package:memora/core/formatters/japanese_era_formatter.dart';
import 'package:memora/presentation/features/timeline/refresh_timeline_callback.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_context.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition.dart';
import 'package:memora/presentation/features/timeline/rows/timeline_row_definition_factory.dart';
import 'package:memora/presentation/features/timeline/timeline_controller.dart';
import 'package:memora/presentation/features/timeline/timeline_display_settings.dart';
import 'package:memora/presentation/features/timeline/timeline_layout_config.dart';

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
    final borderColor = Theme.of(context).colorScheme.outlineVariant;
    final dataTableKey = useMemoized(() => GlobalKey(), []);
    final rowDefinitions = buildDefaultTimelineRowDefinitions(
      groupWithMembers,
      layoutConfig: _layoutConfig,
    );
    final rowIds = rowDefinitions
        .map((definition) => definition.rowId)
        .toList(growable: false);
    final timelineController = useTimelineController(
      context: context,
      ref: ref,
      groupWithMembers: groupWithMembers,
      rowIds: rowIds,
      layoutConfig: _layoutConfig,
      onSetRefreshCallback: onSetRefreshCallback,
    );
    final rowContext = TimelineRowContext(
      groupWithMembers: groupWithMembers,
      controller: timelineController,
      layoutConfig: _layoutConfig,
      onTripManagementSelected: onTripManagementSelected,
      onDvcPointCalculationPressed: onDvcPointCalculationPressed,
    );
    final visibleRowDefinitions = rowDefinitions
        .where((definition) => definition.isVisible(rowContext))
        .toList(growable: false);

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

    Widget buildScrollableDataCells(TimelineRowDefinition rowDefinition) {
      final columnCount = 2 + timelineController.visibleYears.length;

      return Row(
        children: List.generate(columnCount, (columnIndex) {
          final width = columnIndex == 0 || columnIndex == columnCount - 1
              ? _layoutConfig.buttonColumnWidth
              : _layoutConfig.yearColumnWidth;

          final isYearColumn =
              columnIndex != 0 && columnIndex != columnCount - 1;
          final year = isYearColumn
              ? timelineController.yearFromColumnIndex(columnIndex)
              : null;

          return SizedBox(
            width: width,
            height: rowContext.rowHeight(rowDefinition.rowId),
            child: GestureDetector(
              onTap: isYearColumn
                  ? () =>
                        rowDefinition.onYearCellTap(context, rowContext, year!)
                  : null,
              child: Container(
                key: year == null ? null : rowDefinition.yearCellKey(year),
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
                  color:
                      rowDefinition.backgroundColor(context, rowContext) ??
                      Colors.transparent,
                ),
                child: isYearColumn
                    ? rowDefinition.buildYearCell(context, rowContext, year!)
                    : const SizedBox.shrink(),
              ),
            ),
          );
        }),
      );
    }

    Widget buildDataRow(int rowIndex, TimelineRowDefinition rowDefinition) {
      final colorScheme = Theme.of(context).colorScheme;
      final rowHeight = rowContext.rowHeight(rowDefinition.rowId);

      return Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('fixed_row_$rowIndex'),
                  onTap: () =>
                      rowDefinition.onFixedColumnTap(context, rowContext),
                  child: Container(
                    width: _layoutConfig.fixedColumnWidth,
                    height: rowHeight,
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
                    child: rowDefinition.buildFixedColumn(context, rowContext),
                  ),
                ),
              ),
              Container(
                width: _layoutConfig.borderWidth,
                height: rowHeight,
                color: borderColor,
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller:
                      timelineController.rowScrollControllers[rowIndex + 1],
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    key: Key('scrollable_row_$rowIndex'),
                    height: rowHeight,
                    child: buildScrollableDataCells(rowDefinition),
                  ),
                ),
              ),
            ],
          ),
          if (rowIndex < visibleRowDefinitions.length)
            Positioned(
              left: 0,
              bottom: -19,
              child: Listener(
                key: Key('row_resizer_icon_$rowIndex'),
                onPointerDown: (event) => timelineController
                    .onRowResizePointerDown(rowDefinition.rowId, event),
                onPointerMove: (event) => timelineController
                    .onRowResizePointerMove(rowDefinition.rowId, event),
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
      return List.generate(visibleRowDefinitions.length, (index) {
        return buildDataRow(index, visibleRowDefinitions[index]);
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
}
