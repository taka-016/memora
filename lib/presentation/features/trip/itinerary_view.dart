import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:uuid/uuid.dart';

class ItineraryView extends HookWidget {
  const ItineraryView({
    super.key,
    required this.tripId,
    required this.items,
    required this.onChanged,
    this.onClose,
  });

  final String? tripId;
  final List<ItineraryItemDto> items;
  final ValueChanged<List<ItineraryItemDto>> onChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final itemsState = useState<List<ItineraryItemDto>>(
      sortItineraryItems(items),
    );
    final errorMessage = useState<String?>(null);

    useEffect(() {
      itemsState.value = sortItineraryItems(items);
      return null;
    }, [items]);

    void notifyChange(List<ItineraryItemDto> updated) {
      final sorted = sortItineraryItems(updated);
      itemsState.value = sorted;
      onChanged(sorted);
    }

    void clearInputs() {
      nameController.clear();
    }

    void addItem() {
      final result = buildItineraryItemFromInput(
        id: const Uuid().v7(),
        tripId: tripId ?? '',
        nameInput: nameController.text,
        startDate: null,
        startTime: null,
        endDate: null,
        endTime: null,
        memoInput: '',
      );
      if (result.errorMessage != null) {
        errorMessage.value = result.errorMessage;
        return;
      }
      final item = result.item;
      if (item == null) {
        return;
      }
      errorMessage.value = null;
      notifyChange([...itemsState.value, item]);
      clearInputs();
    }

    Future<void> showEditBottomSheet(ItineraryItemDto item) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return ItineraryItemEditBottomSheet(
            item: item,
            onSaved: (updatedItem) {
              final updated = List<ItineraryItemDto>.from(itemsState.value);
              final index = updated.indexWhere(
                (current) => current.id == updatedItem.id,
              );
              if (index == -1) {
                return;
              }
              updated[index] = updatedItem;
              notifyChange(updated);
            },
            onDeleted: (deletedItem) {
              notifyChange(
                itemsState.value
                    .where((current) => current.id != deletedItem.id)
                    .toList(),
              );
            },
          );
        },
      );
    }

    Widget buildHeader() {
      return Row(
        children: [
          const Text(
            '旅程',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            icon: const Icon(Icons.close),
          ),
        ],
      );
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

    Widget buildInputArea() {
      return Column(
        children: [
          TextField(
            key: const Key('itinerary_name_field'),
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '項目名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(onPressed: addItem, child: const Text('追加')),
          ),
        ],
      );
    }

    Widget buildListItem(ItineraryItemDto item) {
      final subtitleParts = <String>[
        if (formatDateTimeRange(item).isNotEmpty) formatDateTimeRange(item),
        if (item.memo?.isNotEmpty == true) item.memo!,
      ];

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: ListTile(
          key: Key('itineraryListItem_${item.id}'),
          dense: true,
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          title: Text(item.name, style: const TextStyle(fontSize: 14)),
          subtitle: subtitleParts.isEmpty
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: subtitleParts
                      .map(
                        (text) =>
                            Text(text, style: const TextStyle(fontSize: 12)),
                      )
                      .toList(),
                ),
          onTap: () => showEditBottomSheet(item),
        ),
      );
    }

    return Column(
      key: const Key('itinerary_view_root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildErrorBanner(),
                if (errorMessage.value != null) const SizedBox(height: 12),
                buildInputArea(),
                const SizedBox(height: 16),
                ...itemsState.value.map(buildListItem),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ItineraryItemEditBottomSheet extends HookWidget {
  const ItineraryItemEditBottomSheet({
    super.key,
    required this.item,
    required this.onSaved,
    required this.onDeleted,
  });

  final ItineraryItemDto item;
  final ValueChanged<ItineraryItemDto> onSaved;
  final ValueChanged<ItineraryItemDto> onDeleted;

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
    final clock = NtpSynchronizedAppClock();

    Future<void> selectStartDate() async {
      final picked = await DatePickerHelper.showCustomDatePicker(
        context,
        initialDate: startDate.value ?? clock.now(),
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
        initialDate: endDate.value ?? (startDate.value ?? clock.now()),
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '旅程編集',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              buildErrorBanner(),
              if (errorMessage.value != null) const SizedBox(height: 12),
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
                  TextButton(
                    onPressed: () {
                      onDeleted(item);
                      Navigator.of(context).pop();
                    },
                    child: const Text('削除'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: save, child: const Text('保存')),
                ],
              ),
            ],
          ),
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
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Align(alignment: Alignment.centerLeft, child: Text(label)),
      const SizedBox(height: 8),
      buildDateTimeField(
        key: dateFieldKey,
        value: dateValue,
        icon: Icons.calendar_today,
        onTap: onDateTap,
      ),
      const SizedBox(height: 8),
      buildDateTimeField(
        key: timeFieldKey,
        value: timeValue,
        icon: Icons.access_time,
        onTap: onTimeTap,
      ),
    ],
  );
}

Widget buildDateTimeField({
  required Key key,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    key: key,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
          Icon(icon, color: Colors.black54),
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

List<ItineraryItemDto> sortItineraryItems(List<ItineraryItemDto> items) {
  return List<ItineraryItemDto>.from(items)..sort(compareItineraryItems);
}

int compareItineraryItems(ItineraryItemDto a, ItineraryItemDto b) {
  final startCompare = compareNullableDateTime(
    a.startDateTime,
    b.startDateTime,
  );
  if (startCompare != 0) {
    return startCompare;
  }

  final endCompare = compareNullableDateTime(a.endDateTime, b.endDateTime);
  if (endCompare != 0) {
    return endCompare;
  }

  return a.name.compareTo(b.name);
}

int compareNullableDateTime(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

DateTime? parseDateTimeInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final match = RegExp(
    r'^(\d{4})/(\d{2})/(\d{2}) (\d{2}):(\d{2})$',
  ).firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final parsed = DateTime(year, month, day, hour, minute);
  if (parsed.year != year ||
      parsed.month != month ||
      parsed.day != day ||
      parsed.hour != hour ||
      parsed.minute != minute) {
    return null;
  }
  return parsed;
}

String formatDateTimeInput(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }
  return [
    dateTime.year.toString().padLeft(4, '0'),
    '/',
    dateTime.month.toString().padLeft(2, '0'),
    '/',
    dateTime.day.toString().padLeft(2, '0'),
    ' ',
    dateTime.hour.toString().padLeft(2, '0'),
    ':',
    dateTime.minute.toString().padLeft(2, '0'),
  ].join();
}

String formatDateTimeLabel(DateTime dateTime) {
  return [
    dateTime.month.toString().padLeft(2, '0'),
    '/',
    dateTime.day.toString().padLeft(2, '0'),
    ' ',
    dateTime.hour.toString().padLeft(2, '0'),
    ':',
    dateTime.minute.toString().padLeft(2, '0'),
  ].join();
}

String formatDateTimeRange(ItineraryItemDto item) {
  if (item.startDateTime != null && item.endDateTime != null) {
    return '${formatDateTimeLabel(item.startDateTime!)} - ${formatDateTimeLabel(item.endDateTime!)}';
  }
  if (item.startDateTime != null) {
    return '開始: ${formatDateTimeLabel(item.startDateTime!)}';
  }
  if (item.endDateTime != null) {
    return '終了: ${formatDateTimeLabel(item.endDateTime!)}';
  }
  return '';
}
