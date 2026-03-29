import 'package:flutter/material.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/presentation/features/timeline/dvc_cell.dart';

class DvcRow extends StatelessWidget {
  const DvcRow({
    super.key,
    required this.years,
    required this.usagesByYear,
    required this.rowHeight,
    required this.yearColumnWidth,
    required this.buttonColumnWidth,
    required this.borderColor,
    required this.borderWidth,
    required this.onYearSelected,
  });

  final List<int> years;
  final Map<int, List<DvcPointUsageDto>> usagesByYear;
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
    final usages = usagesByYear[year] ?? const <DvcPointUsageDto>[];

    return SizedBox(
      width: yearColumnWidth,
      height: rowHeight,
      child: GestureDetector(
        onTap: () => onYearSelected(year),
        child: _buildCellContainer(
          key: Key('dvc_point_usage_cell_$year'),
          child: usages.isEmpty
              ? const SizedBox.shrink()
              : DvcCell(
                  usages: usages,
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
