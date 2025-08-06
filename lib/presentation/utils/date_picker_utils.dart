import 'package:flutter/material.dart';

/// DatePickerに関するユーティリティクラス
class DatePickerUtils {
  /// カスタマイズされたDatePickerを表示する
  ///
  /// OKボタンとキャンセルボタンを透明にして、日付タップで直接確定するUXを提供
  static Future<DateTime?> showCustomDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: Theme.of(context).primaryColor,
              headerForegroundColor: Colors.white,
              dayStyle: const TextStyle(fontSize: 14),
              yearStyle: const TextStyle(fontSize: 14),
              cancelButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
              confirmButtonStyle: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            dialogTheme: const DialogThemeData(actionsPadding: EdgeInsets.zero),
          ),
          child: child!,
        );
      },
    );
  }
}
