import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CalendarMonthPickerDialog extends StatefulWidget {
  const CalendarMonthPickerDialog({super.key, required this.month});

  final DateTime month;

  @override
  State<CalendarMonthPickerDialog> createState() =>
      _CalendarMonthPickerDialogState();
}

class _CalendarMonthPickerDialogState extends State<CalendarMonthPickerDialog> {
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.month.year;
    _month = widget.month.month;
    _yearController = FixedExtentScrollController(initialItem: _year - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemExtent = 40.0 * MediaQuery.textScalerOf(context).scale(1);
    return AlertDialog(
      title: const Text('年月を選択'),
      content: SizedBox(
        width: 280,
        height: 200,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: CupertinoPicker.builder(
                scrollController: _yearController,
                itemExtent: itemExtent,
                childCount: 9999,
                onSelectedItemChanged: (index) => _year = index + 1,
                itemBuilder: (context, index) => Center(
                  child: FittedBox(child: Text('${index + 1}年')),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: CupertinoPicker.builder(
                scrollController: _monthController,
                itemExtent: itemExtent,
                childCount: 12,
                onSelectedItemChanged: (index) => _month = index + 1,
                itemBuilder: (context, index) => Center(
                  child: FittedBox(child: Text('${index + 1}月')),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DateTime(_year, _month)),
          child: const Text('移動'),
        ),
      ],
    );
  }
}
