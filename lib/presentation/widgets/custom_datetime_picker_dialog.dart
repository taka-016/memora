import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 曜日を取得するヘルパー関数
String _getWeekdayString(DateTime date) {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  return weekdays[date.weekday % 7];
}

/// 日時を「YYYY年MM月DD日 (曜) HH:MM」形式でフォーマットする
String _formatDateTimeWithWeekday(DateTime dateTime) {
  final hourMinute =
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 (${_getWeekdayString(dateTime)}) $hourMinute';
}

/// 年月日時分入力のフォーマット処理クラス
class DateTimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // 数字以外の文字を除去
    final numbersOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // 12桁を超えた場合は切り詰める（YYYYMMDDHHMM）
    final truncated = numbersOnly.length > 12
        ? numbersOnly.substring(0, 12)
        : numbersOnly;

    // 自動フォーマット処理
    String formatted = '';
    if (truncated.isNotEmpty) {
      if (truncated.length <= 4) {
        formatted = truncated;
      } else if (truncated.length <= 6) {
        formatted = '${truncated.substring(0, 4)}/${truncated.substring(4)}';
      } else if (truncated.length <= 8) {
        formatted =
            '${truncated.substring(0, 4)}/${truncated.substring(4, 6)}/${truncated.substring(6)}';
      } else if (truncated.length <= 10) {
        formatted =
            '${truncated.substring(0, 4)}/${truncated.substring(4, 6)}/${truncated.substring(6, 8)} ${truncated.substring(8)}';
      } else {
        formatted =
            '${truncated.substring(0, 4)}/${truncated.substring(4, 6)}/${truncated.substring(6, 8)} ${truncated.substring(8, 10)}:${truncated.substring(10)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// フォーマットされた日時文字列から日時を解析し、バリデーションを行う
class _DateTimeValidator {
  static DateTime? validateAndParse(
    String formattedDateTimeText,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    // スラッシュ、スペース、コロンを除去して数字のみ取得
    final numbersOnly = formattedDateTimeText
        .replaceAll('/', '')
        .replaceAll(' ', '')
        .replaceAll(':', '');

    // 12桁でない場合は無効
    if (numbersOnly.length != 12) {
      return null;
    }

    try {
      final year = int.parse(numbersOnly.substring(0, 4));
      final month = int.parse(numbersOnly.substring(4, 6));
      final day = int.parse(numbersOnly.substring(6, 8));
      final hour = int.parse(numbersOnly.substring(8, 10));
      final minute = int.parse(numbersOnly.substring(10, 12));

      final dateTime = DateTime(year, month, day, hour, minute);

      // 入力値が有効な日時かチェック
      if (dateTime.year != year ||
          dateTime.month != month ||
          dateTime.day != day ||
          dateTime.hour != hour ||
          dateTime.minute != minute) {
        return null;
      }

      // 範囲チェック（日付部分のみ）
      final dateOnly = DateTime(year, month, day);
      final firstDateOnly = DateTime(
        firstDate.year,
        firstDate.month,
        firstDate.day,
      );
      final lastDateOnly = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );

      if (dateOnly.isBefore(firstDateOnly) || dateOnly.isAfter(lastDateOnly)) {
        return null;
      }

      return dateTime;
    } catch (e) {
      return null;
    }
  }
}

/// 日時選択用のカスタムピッカーダイアログ
class CustomDateTimePickerDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDateTimePickerDialog({
    super.key,
    required this.initialDateTime,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomDateTimePickerDialog> createState() =>
      _CustomDateTimePickerDialogState();
}

class _CustomDateTimePickerDialogState
    extends State<CustomDateTimePickerDialog> {
  late DateTime _selectedDateTime;
  late DateTime _displayDate;
  bool _isMonthChanging = false;
  bool _isInputMode = false;
  late TextEditingController _dateTimeController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _displayDate = widget.initialDateTime;
    _dateTimeController = TextEditingController();
    _updateController();
  }

  @override
  void dispose() {
    _dateTimeController.dispose();
    super.dispose();
  }

  void _updateController() {
    final year = _selectedDateTime.year.toString();
    final month = _selectedDateTime.month.toString().padLeft(2, '0');
    final day = _selectedDateTime.day.toString().padLeft(2, '0');
    final hour = _selectedDateTime.hour.toString().padLeft(2, '0');
    final minute = _selectedDateTime.minute.toString().padLeft(2, '0');
    _dateTimeController.text = '$year/$month/$day $hour:$minute';
  }

  void _onDisplayedMonthChanged(DateTime date) {
    setState(() {
      if (_displayDate.month == date.month) {
        _isMonthChanging = true;
      }
      _displayDate = date;
    });
  }

  void _onDateSelected(DateTime date) {
    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      _selectedDateTime.hour,
      _selectedDateTime.minute,
    );

    setState(() {
      _selectedDateTime = newDateTime;
    });

    if (!_isMonthChanging &&
        date !=
            DateTime(
              widget.initialDateTime.year,
              widget.initialDateTime.month,
              widget.initialDateTime.day,
            )) {
      // 日付が選択されたら時刻選択モードに移行
      _switchToTimeMode();
    }

    setState(() {
      _isMonthChanging = false;
    });
  }

  void _onTimeChanged(TimeOfDay time) {
    final newDateTime = DateTime(
      _selectedDateTime.year,
      _selectedDateTime.month,
      _selectedDateTime.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _selectedDateTime = newDateTime;
    });

    Navigator.of(context).pop(_selectedDateTime);
  }

  /// 入力フィールドビューに切り替える
  void _switchToInputMode() {
    setState(() {
      _isInputMode = true;
      _errorMessage = null;
    });
    _updateController();
  }

  /// カレンダービューに切り替える
  void _switchToCalendarMode() {
    setState(() {
      _isInputMode = false;
      _errorMessage = null;
    });
  }

  /// 時刻選択モードに切り替える
  void _switchToTimeMode() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    ).then((time) {
      if (time != null) {
        _onTimeChanged(time);
      }
    });
  }

  /// 入力フィールドから日時を確定する
  void _confirmInputDateTime() {
    setState(() {
      _errorMessage = null;
    });

    final dateTime = _DateTimeValidator.validateAndParse(
      _dateTimeController.text,
      widget.firstDate,
      widget.lastDate,
    );

    if (dateTime == null) {
      setState(() {
        _errorMessage = '有効な日時を入力してください';
      });
      return;
    }

    setState(() {
      _selectedDateTime = dateTime;
    });

    Navigator.of(context).pop(_selectedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: _switchToInputMode,
                  child: Text(
                    _formatDateTimeWithWeekday(_selectedDateTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ビューモードに応じてコンテンツを切り替え
            SizedBox(
              height: 300,
              child: _isInputMode ? _buildInputView() : _buildCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  /// カレンダービューを構築
  Widget _buildCalendarView() {
    return Column(
      children: [
        Expanded(
          child: CalendarDatePicker(
            initialDate: _selectedDateTime,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onDateChanged: _onDateSelected,
            onDisplayedMonthChanged: _onDisplayedMonthChanged,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _switchToTimeMode,
          child: Text(
            '時刻を選択 (${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')})',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedDateTime),
          child: const Text('確定'),
        ),
      ],
    );
  }

  /// 入力フィールドビューを構築
  Widget _buildInputView() {
    return Column(
      children: [
        const SizedBox(height: 32),
        // 入力フィールド（単一フィールドで自動フォーマット）
        TextField(
          key: const Key('datetime_field'),
          controller: _dateTimeController,
          keyboardType: TextInputType.number,
          inputFormatters: [DateTimeInputFormatter()],
          decoration: const InputDecoration(
            labelText: '日時 (YYYY/MM/DD HH:MM)',
            hintText: 'YYYY/MM/DD HH:MM',
            border: OutlineInputBorder(),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 14,
            ),
          ),
        ],
        const Spacer(),
        // ボタン
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _switchToCalendarMode,
              child: const Text('キャンセル'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _confirmInputDateTime,
              child: const Text('確定'),
            ),
          ],
        ),
      ],
    );
  }
}

/// CustomDateTimePickerDialogを表示するヘルパー関数
Future<DateTime?> showCustomDateTimePickerDialog(
  BuildContext context, {
  required DateTime initialDateTime,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomDateTimePickerDialog(
      initialDateTime: initialDateTime,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
