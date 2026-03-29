import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/trip_cell.dart';

class TripRow extends StatelessWidget {
  const TripRow({
    super.key,
    required this.years,
    required this.tripsByYear,
    required this.rowHeight,
    required this.yearColumnWidth,
    required this.buttonColumnWidth,
    required this.borderColor,
    required this.borderWidth,
    required this.onYearSelected,
  });

  final List<int> years;
  final Map<int, List<TripEntryDto>> tripsByYear;
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
    final trips = tripsByYear[year] ?? const <TripEntryDto>[];

    return SizedBox(
      width: yearColumnWidth,
      height: rowHeight,
      child: GestureDetector(
        onTap: () => onYearSelected(year),
        child: _buildCellContainer(
          child: TripCell(
            trips: trips,
            availableHeight: rowHeight,
            availableWidth: yearColumnWidth,
          ),
        ),
      ),
    );
  }

  Widget _buildCellContainer({required Widget child}) {
    return Container(
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
