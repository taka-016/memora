import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/core/app_logger.dart';

String _getWeekdayString(DateTime date) {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  return weekdays[date.weekday % 7];
}

String _formatDateWithWeekday(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日 (${_getWeekdayString(date)})';
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    final numbersOnly = newText.replaceAll(RegExp(r'[^0-9]'), '');

    final truncated = numbersOnly.length > 8
        ? numbersOnly.substring(0, 8)
        : numbersOnly;

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

class _DateValidator {
  static DateTime? validateAndParse(
    String formattedDateText,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    final numbersOnly = formattedDateText.replaceAll('/', '');

    if (numbersOnly.length != 8) {
      return null;
    }

    try {
      final year = int.parse(numbersOnly.substring(0, 4));
      final month = int.parse(numbersOnly.substring(4, 6));
      final day = int.parse(numbersOnly.substring(6, 8));

      final date = DateTime(year, month, day);

      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }

      if (date.isBefore(firstDate) || date.isAfter(lastDate)) {
        return null;
      }

      return date;
    } catch (e, stack) {
      logger.e(
        '_DateValidator.validateAndParse: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }
}

class CustomDatePickerDialog extends HookWidget {
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
  Widget build(BuildContext context) {
    final selectedDate = useState(initialDate);
    final displayDate = useState(initialDate);
    final isMonthChanging = useState(false);
    final isInputMode = useState(false);
    final errorMessage = useState<String?>(null);
    final dateController = useTextEditingController();

    void updateController() {
      final year = selectedDate.value.year.toString();
      final month = selectedDate.value.month.toString().padLeft(2, '0');
      final day = selectedDate.value.day.toString().padLeft(2, '0');
      dateController.text = '$year/$month/$day';
    }

    void onDisplayedMonthChanged(DateTime date) {
      if (displayDate.value.month == date.month) {
        isMonthChanging.value = true;
      }
      displayDate.value = date;
    }

    void onDateSelected(DateTime date) {
      selectedDate.value = date;

      if (!isMonthChanging.value && date != initialDate) {
        Navigator.of(context).pop(selectedDate.value);
      }

      isMonthChanging.value = false;
    }

    void switchToInputMode() {
      isInputMode.value = true;
      errorMessage.value = null;
      updateController();
    }

    void switchToCalendarMode() {
      isInputMode.value = false;
      errorMessage.value = null;
    }

    void confirmInputDate() {
      errorMessage.value = null;

      final date = _DateValidator.validateAndParse(
        dateController.text,
        firstDate,
        lastDate,
      );

      if (date == null) {
        errorMessage.value = '有効な日付を入力してください';
        return;
      }

      selectedDate.value = date;

      Navigator.of(context).pop(selectedDate.value);
    }

    useEffect(() {
      updateController();
      return null;
    }, [selectedDate.value]);

    Widget buildHeader(BuildContext context) {
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
            onTap: switchToInputMode,
            child: Text(
              key: const Key('date_header'),
              _formatDateWithWeekday(selectedDate.value),
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

    Widget buildDateInputField() {
      return TextField(
        key: const Key('date_field'),
        controller: dateController,
        keyboardType: TextInputType.number,
        inputFormatters: [DateInputFormatter()],
        decoration: const InputDecoration(
          labelText: '日付 (YYYY/MM/DD)',
          hintText: 'YYYY/MM/DD',
          border: OutlineInputBorder(),
        ),
      );
    }

    Widget buildErrorMessage() {
      if (errorMessage.value == null) return const SizedBox.shrink();

      return Column(
        children: [
          const SizedBox(height: 16),
          Text(
            errorMessage.value!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    Widget buildInputViewButtons() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: switchToCalendarMode,
            child: const Text('キャンセル'),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: confirmInputDate, child: const Text('確定')),
        ],
      );
    }

    Widget buildInputView() {
      return Column(
        children: [
          const SizedBox(height: 32),
          buildDateInputField(),
          buildErrorMessage(),
          const Spacer(),
          buildInputViewButtons(),
        ],
      );
    }

    Widget buildCalendarView() {
      return CalendarDatePicker(
        initialDate: selectedDate.value,
        firstDate: firstDate,
        lastDate: lastDate,
        onDateChanged: onDateSelected,
        onDisplayedMonthChanged: onDisplayedMonthChanged,
      );
    }

    Widget buildContent() {
      return SizedBox(
        height: 300,
        child: isInputMode.value ? buildInputView() : buildCalendarView(),
      );
    }

    Widget buildDialog(BuildContext context) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHeader(context),
              const SizedBox(height: 16),
              buildContent(),
            ],
          ),
        ),
      );
    }

    return buildDialog(context);
  }
}

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
