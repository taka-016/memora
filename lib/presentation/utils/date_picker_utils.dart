import 'package:flutter/material.dart';
import '../shared/dialogs/custom_date_picker_dialog.dart';

/// DatePickerに関するユーティリティクラス
class DatePickerUtils {
  /// カスタマイズされたDatePickerを表示する
  ///
  /// 日付タップで直接確定するUXを提供
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
