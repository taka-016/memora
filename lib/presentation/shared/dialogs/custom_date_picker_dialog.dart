import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 日付から曜日文字列を取得する
String _getWeekdayString(DateTime date) {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  return weekdays[date.weekday % 7];
}

/// 日付を「YYYY年MM月DD日 (曜)」形式でフォーマットする
String _formatDateWithWeekday(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日 (${_getWeekdayString(date)})';
}

/// 年月日入力のフォーマット処理クラス
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // 数字以外の文字を除去
    final numbersOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    // 8桁を超えた場合は切り詰める
    final truncated = numbersOnly.length > 8
        ? numbersOnly.substring(0, 8)
        : numbersOnly;

    // 自動フォーマット処理
    String formatted = '';
    if (truncated.isNotEmpty) {
      if (truncated.length <= 4) {
        formatted = truncated;
      } else if (truncated.length <= 6) {
        formatted = '${truncated.substring(0, 4)}/${truncated.substring(4)}';
      } else {
        formatted =
            '${truncated.substring(0, 4)}/${truncated.substring(4, 6)}/${truncated.substring(6)}';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// フォーマットされた日付文字列から日付を解析し、バリデーションを行う
class _DateValidator {
  static DateTime? validateAndParse(
    String formattedDateText,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    // スラッシュを除去して数字のみ取得
    final numbersOnly = formattedDateText.replaceAll('/', '');

    // 8桁でない場合は無効
    if (numbersOnly.length != 8) {
      return null;
    }

    try {
      final year = int.parse(numbersOnly.substring(0, 4));
      final month = int.parse(numbersOnly.substring(4, 6));
      final day = int.parse(numbersOnly.substring(6, 8));

      final date = DateTime(year, month, day);

      // 入力値が有効な日付かチェック
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }

      // 範囲チェック
      if (date.isBefore(firstDate) || date.isAfter(lastDate)) {
        return null;
      }

      return date;
    } catch (e) {
      return null;
    }
  }
}

/// 日付タップで直接確定するカスタムDatePickerDialog
class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayDate;
  bool _isMonthChanging = false;
  bool _isInputMode = false;
  late TextEditingController _dateController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayDate = widget.initialDate;
    _dateController = TextEditingController();
    _updateController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _updateController() {
    final year = _selectedDate.year.toString();
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    _dateController.text = '$year/$month/$day';
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
    setState(() {
      _selectedDate = date;
    });

    if (!_isMonthChanging && date != widget.initialDate) {
      Navigator.of(context).pop(_selectedDate);
    }

    setState(() {
      _isMonthChanging = false;
    });
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

  /// 入力フィールドから日付を確定する
  void _confirmInputDate() {
    setState(() {
      _errorMessage = null;
    });

    final date = _DateValidator.validateAndParse(
      _dateController.text,
      widget.firstDate,
      widget.lastDate,
    );

    if (date == null) {
      setState(() {
        _errorMessage = '有効な日付を入力してください';
      });
      return;
    }

    setState(() {
      _selectedDate = date;
    });

    // 直接入力確定時にDatePickerを閉じる
    Navigator.of(context).pop(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return _buildDialog(context);
  }

  /// ダイアログ全体を構築
  Widget _buildDialog(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  /// ヘッダー部分を構築
  Widget _buildHeader(BuildContext context) {
    return Container(
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
            _formatDateWithWeekday(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// コンテンツ部分を構築
  Widget _buildContent() {
    return SizedBox(
      height: 300,
      child: _isInputMode ? _buildInputView() : _buildCalendarView(),
    );
  }

  /// カレンダービューを構築
  Widget _buildCalendarView() {
    return CalendarDatePicker(
      initialDate: _selectedDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      onDateChanged: _onDateSelected,
      onDisplayedMonthChanged: _onDisplayedMonthChanged,
    );
  }

  /// 入力フィールドビューを構築
  Widget _buildInputView() {
    return Column(
      children: [
        const SizedBox(height: 32),
        _buildDateInputField(),
        _buildErrorMessage(),
        const Spacer(),
        _buildInputViewButtons(),
      ],
    );
  }

  /// 日付入力フィールドを構築
  Widget _buildDateInputField() {
    return TextField(
      key: const Key('date_field'),
      controller: _dateController,
      keyboardType: TextInputType.number,
      inputFormatters: [DateInputFormatter()],
      decoration: const InputDecoration(
        labelText: '日付 (YYYY/MM/DD)',
        hintText: 'YYYY/MM/DD',
        border: OutlineInputBorder(),
      ),
    );
  }

  /// エラーメッセージを構築
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 入力ビューのボタン群を構築
  Widget _buildInputViewButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _switchToCalendarMode,
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 8),
        TextButton(onPressed: _confirmInputDate, child: const Text('確定')),
      ],
    );
  }
}

/// CustomDatePickerDialogを表示するヘルパー関数
Future<DateTime?> showCustomDatePickerDialog(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomDatePickerDialog(
      initialDate: initialDate.add(const Duration(minutes: 1)),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}
