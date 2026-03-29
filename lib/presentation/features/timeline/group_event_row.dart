import 'package:flutter/material.dart';
import 'package:memora/application/dtos/group/group_event_dto.dart';
import 'package:memora/presentation/features/timeline/group_event_cell.dart';

class GroupEventRow extends StatelessWidget {
  const GroupEventRow({
    super.key,
    required this.years,
    required this.eventsByYear,
    required this.rowHeight,
    required this.yearColumnWidth,
    required this.buttonColumnWidth,
    required this.borderColor,
    required this.borderWidth,
    required this.onYearSelected,
  });

  final List<int> years;
  final Map<int, GroupEventDto> eventsByYear;
  final double rowHeight;
  final double yearColumnWidth;
  final double buttonColumnWidth;
  final Color borderColor;
  final double borderWidth;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSideSpacer(),
        ...years.map(_buildYearCell),
        _buildSideSpacer(),
      ],
    );
  }

  Widget _buildSideSpacer() {
    return SizedBox(
      width: buttonColumnWidth,
      height: rowHeight,
      child: _buildCellContainer(child: const SizedBox.shrink()),
    );
  }

  Widget _buildYearCell(int year) {
    final event = eventsByYear[year];

    return SizedBox(
      width: yearColumnWidth,
      height: rowHeight,
      child: GestureDetector(
        onTap: () => onYearSelected(year),
        child: _buildCellContainer(
          key: Key('group_event_cell_$year'),
          child: event == null
              ? const SizedBox.shrink()
              : GroupEventCell(
                  memo: event.memo,
                  availableHeight: rowHeight,
                  availableWidth: yearColumnWidth,
                ),
        ),
      ),
    );
  }

  Widget _buildCellContainer({required Widget child, Key? key}) {
    return Container(
      key: key,
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor, width: borderWidth),
          right: BorderSide(color: borderColor, width: borderWidth),
        ),
        color: Colors.lightBlue.shade50,
      ),
      child: child,
    );
  }
}
