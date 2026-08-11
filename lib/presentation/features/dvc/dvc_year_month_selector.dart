import 'package:flutter/material.dart';
import 'package:memora/presentation/features/dvc/dvc_point_calculation_date_utils.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/supported_year_range.dart';

class DvcYearMonthSelector extends StatelessWidget {
  const DvcYearMonthSelector({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TextButton(
          onPressed: () async {
            final picked = await DatePickerHelper.showCustomDatePicker(
              context,
              initialDate: selected,
              firstDate: DateTime(SupportedYearRange.firstYear, 1),
              lastDate: DateTime(SupportedYearRange.lastYear, 12),
            );
            if (picked == null) {
              return;
            }
            onSelected(DateTime(picked.year, picked.month));
          },
          child: Text(dvcFormatYearMonth(selected)),
        ),
      ],
    );
  }
}
