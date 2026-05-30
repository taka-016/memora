import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';

class ItineraryItemEditBottomSheet extends HookWidget {
  const ItineraryItemEditBottomSheet({
    super.key,
    required this.item,
    this.tripStartDate,
    this.location,
    this.onLocationSelectionRequested,
    required this.onSaved,
    this.clock,
  });

  final ItineraryItemDto item;
  final DateTime? tripStartDate;
  final LocationDto? location;
  final VoidCallback? onLocationSelectionRequested;
  final ValueChanged<ItineraryItemDto> onSaved;
  final AppClock? clock;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: item.name);
    final startDate = useState<DateTime?>(
      datePartOfDateTime(item.startDateTime),
    );
    final startTime = useState<TimeOfDay?>(
      timePartOfDateTime(item.startDateTime),
    );
    final endDate = useState<DateTime?>(datePartOfDateTime(item.endDateTime));
    final endTime = useState<TimeOfDay?>(timePartOfDateTime(item.endDateTime));
    final memoController = useTextEditingController(text: item.memo ?? '');
    final errorMessage = useState<String?>(null);
    final effectiveClock = clock ?? NtpSynchronizedAppClock();

    DateTime initialDateFor(DateTime? selectedDate, {DateTime? fallbackDate}) {
      return selectedDate ??
          fallbackDate ??
          tripStartDate ??
          effectiveClock.now();
    }

    Future<void> selectStartDate() async {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: initialDateFor(startDate.value),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        startDate.value = picked;
        errorMessage.value = null;
      }
    }

    Future<void> selectStartTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: startTime.value ?? TimeOfDay.now(),
      );
      if (picked != null) {
        startTime.value = picked;
        errorMessage.value = null;
      }
    }

    Future<void> selectEndDate() async {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: initialDateFor(
          endDate.value,
          fallbackDate: startDate.value,
        ),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        endDate.value = picked;
        errorMessage.value = null;
      }
    }

    Future<void> selectEndTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: endTime.value ?? (startTime.value ?? TimeOfDay.now()),
      );
      if (picked != null) {
        endTime.value = picked;
        errorMessage.value = null;
      }
    }

    void clearStartDateTime() {
      startDate.value = null;
      startTime.value = null;
      errorMessage.value = null;
    }

    void clearEndDateTime() {
      endDate.value = null;
      endTime.value = null;
      errorMessage.value = null;
    }

    void save() {
      final result = buildItineraryItemFromInput(
        id: item.id,
        tripId: item.tripId,
        nameInput: nameController.text,
        startDate: startDate.value,
        startTime: startTime.value,
        endDate: endDate.value,
        endTime: endTime.value,
        memoInput: memoController.text,
      );
      if (result.errorMessage != null) {
        errorMessage.value = result.errorMessage;
        return;
      }
      if (result.item == null) {
        return;
      }

      onSaved(result.item!);
      Navigator.of(context).pop();
    }

    Widget buildErrorBanner() {
      if (errorMessage.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          errorMessage.value!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const Key('itinerary_edit_bottom_sheet_handle'),
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            buildErrorBanner(),
            const SizedBox(height: 12),
            TextField(
              key: const Key('itinerary_edit_name_field'),
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '項目名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            buildDateTimeSection(
              label: '開始日時',
              dateValue: formatDate(startDate.value),
              timeValue: formatTime(startTime.value),
              dateFieldKey: const Key('itinerary_edit_start_date_field'),
              timeFieldKey: const Key('itinerary_edit_start_time_field'),
              onDateTap: selectStartDate,
              onTimeTap: selectStartTime,
              clearDateFieldKey: const Key(
                'itinerary_edit_start_datetime_clear_button',
              ),
              onClearDateTime:
                  startDate.value != null || startTime.value != null
                  ? clearStartDateTime
                  : null,
            ),
            const SizedBox(height: 12),
            buildDateTimeSection(
              label: '終了日時',
              dateValue: formatDate(endDate.value),
              timeValue: formatTime(endTime.value),
              dateFieldKey: const Key('itinerary_edit_end_date_field'),
              timeFieldKey: const Key('itinerary_edit_end_time_field'),
              onDateTap: selectEndDate,
              onTimeTap: selectEndTime,
              clearDateFieldKey: const Key(
                'itinerary_edit_end_datetime_clear_button',
              ),
              onClearDateTime: endDate.value != null || endTime.value != null
                  ? clearEndDateTime
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('itinerary_edit_memo_field'),
              controller: memoController,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onLocationSelectionRequested,
                  icon: const Icon(Icons.place),
                  label: Text(location == null ? '場所を指定' : '場所を変更'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: save, child: const Text('保存')),
              ],
            ),
            if (location?.name?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(location!.name!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ItineraryItemInputResult {
  const ItineraryItemInputResult({this.item, this.errorMessage});

  final ItineraryItemDto? item;
  final String? errorMessage;
}

ItineraryItemInputResult buildItineraryItemFromInput({
  required String id,
  required String tripId,
  required String nameInput,
  required DateTime? startDate,
  required TimeOfDay? startTime,
  required DateTime? endDate,
  required TimeOfDay? endTime,
  required String memoInput,
}) {
  final name = nameInput.trim();
  if (name.isEmpty) {
    return const ItineraryItemInputResult(errorMessage: '旅程項目名を入力してください');
  }

  final startDateTime = buildDateTime(startDate, startTime);
  final endDateTime = buildDateTime(endDate, endTime);
  if (startDateTime != null &&
      endDateTime != null &&
      endDateTime.isBefore(startDateTime)) {
    return const ItineraryItemInputResult(errorMessage: '終了日時は開始日時以降を入力してください');
  }

  final memo = memoInput.trim();
  return ItineraryItemInputResult(
    item: ItineraryItemDto(
      id: id,
      tripId: tripId,
      name: name,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      memo: memo.isEmpty ? null : memo,
    ),
  );
}

Widget buildDateTimeSection({
  required String label,
  required String dateValue,
  required String timeValue,
  required Key dateFieldKey,
  required Key timeFieldKey,
  required VoidCallback onDateTap,
  required VoidCallback onTimeTap,
  required Key clearDateFieldKey,
  required VoidCallback? onClearDateTime,
}) {
  return SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(alignment: Alignment.centerLeft, child: Text(label)),
        const SizedBox(height: 8),
        buildDateTimeField(
          key: dateFieldKey,
          value: dateValue,
          icon: Icons.calendar_today,
          onTap: onDateTap,
          clearKey: clearDateFieldKey,
          onClear: onClearDateTime,
          clearTooltip: '$labelをクリア',
        ),
        const SizedBox(height: 8),
        buildDateTimeField(
          key: timeFieldKey,
          value: timeValue,
          icon: Icons.access_time,
          onTap: onTimeTap,
        ),
      ],
    ),
  );
}

Widget buildDateTimeField({
  required Key key,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
  Key? clearKey,
  VoidCallback? onClear,
  String? clearTooltip,
}) {
  return InkWell(
    key: key,
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                Tooltip(
                  message: clearTooltip ?? '日時をクリア',
                  child: GestureDetector(
                    key: clearKey,
                    onTap: onClear,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(Icons.clear, color: Colors.black54),
                    ),
                  ),
                ),
              Icon(icon, color: Colors.black54),
            ],
          ),
        ],
      ),
    ),
  );
}

DateTime? buildDateTime(DateTime? date, TimeOfDay? time) {
  if (date == null) {
    return null;
  }
  final effectiveTime = time ?? const TimeOfDay(hour: 0, minute: 0);
  return DateTime(
    date.year,
    date.month,
    date.day,
    effectiveTime.hour,
    effectiveTime.minute,
  );
}

DateTime? datePartOfDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return null;
  }
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

TimeOfDay? timePartOfDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return null;
  }
  return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
}

String formatDate(DateTime? date) {
  if (date == null) {
    return '日付を選択';
  }
  return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
}

String formatTime(TimeOfDay? time) {
  if (time == null) {
    return '時間を選択';
  }
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
