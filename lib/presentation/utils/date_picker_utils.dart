import 'package:flutter/material.dart';
import '../widgets/custom_date_picker_dialog.dart';
import '../widgets/custom_datetime_picker_dialog.dart';

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

  /// カスタマイズされたDateTimePickerを表示する
  ///
  /// 日時（時分まで）の入力が可能
  static Future<DateTime?> showCustomDateTimePicker(
    BuildContext context, {
    required DateTime initialDateTime,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showCustomDateTimePickerDialog(
      context,
      initialDateTime: initialDateTime,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }
}
