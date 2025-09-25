import 'package:flutter/material.dart';
import 'package:memora/presentation/shared/dialogs/custom_date_picker_dialog.dart';

class DatePickerHelper {
  static Future<DateTime?> showCustomDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showCustomDatePickerDialog(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
