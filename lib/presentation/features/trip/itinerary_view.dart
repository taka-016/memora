import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
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
    final startDateTimeController = useTextEditingController();
    final endDateTimeController = useTextEditingController();
    final memoController = useTextEditingController();
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
      startDateTimeController.clear();
      endDateTimeController.clear();
      memoController.clear();
    }

    void addItem() {
      final result = buildItineraryItemFromInput(
        id: const Uuid().v7(),
        tripId: tripId ?? '',
        nameInput: nameController.text,
        startDateTimeInput: startDateTimeController.text,
        endDateTimeInput: endDateTimeController.text,
        memoInput: memoController.text,
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
          TextField(
            key: const Key('itinerary_start_datetime_field'),
            controller: startDateTimeController,
            decoration: const InputDecoration(
              labelText: '開始日時',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('itinerary_end_datetime_field'),
            controller: endDateTimeController,
            decoration: const InputDecoration(
              labelText: '終了日時',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('itinerary_memo_field'),
            controller: memoController,
            decoration: const InputDecoration(
              labelText: 'メモ',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
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
        buildErrorBanner(),
        if (errorMessage.value != null) const SizedBox(height: 12),
        buildInputArea(),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: itemsState.value.map(buildListItem).toList(),
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
    final startDateTimeController = useTextEditingController(
      text: formatDateTimeInput(item.startDateTime),
    );
    final endDateTimeController = useTextEditingController(
      text: formatDateTimeInput(item.endDateTime),
    );
    final memoController = useTextEditingController(text: item.memo ?? '');
    final errorMessage = useState<String?>(null);

    void save() {
      final result = buildItineraryItemFromInput(
        id: item.id,
        tripId: item.tripId,
        nameInput: nameController.text,
        startDateTimeInput: startDateTimeController.text,
        endDateTimeInput: endDateTimeController.text,
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
              TextField(
                key: const Key('itinerary_edit_start_datetime_field'),
                controller: startDateTimeController,
                decoration: const InputDecoration(
                  labelText: '開始日時',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('itinerary_edit_end_datetime_field'),
                controller: endDateTimeController,
                decoration: const InputDecoration(
                  labelText: '終了日時',
                  border: OutlineInputBorder(),
                ),
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
  required String startDateTimeInput,
  required String endDateTimeInput,
  required String memoInput,
}) {
  final name = nameInput.trim();
  if (name.isEmpty) {
    return const ItineraryItemInputResult(errorMessage: '旅程項目名を入力してください');
  }

  final startDateTime = parseDateTimeInput(startDateTimeInput);
  final endDateTime = parseDateTimeInput(endDateTimeInput);
  if (startDateTimeInput.trim().isNotEmpty && startDateTime == null) {
    return const ItineraryItemInputResult(
      errorMessage: '開始日時はyyyy/MM/dd HH:mm形式で入力してください',
    );
  }
  if (endDateTimeInput.trim().isNotEmpty && endDateTime == null) {
    return const ItineraryItemInputResult(
      errorMessage: '終了日時はyyyy/MM/dd HH:mm形式で入力してください',
    );
  }
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
