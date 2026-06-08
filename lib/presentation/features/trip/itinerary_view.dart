import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/presentation/features/trip/itinerary_item_edit_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/itinerary_list.dart';
import 'package:uuid/uuid.dart';

class ItineraryView extends HookWidget {
  const ItineraryView({
    super.key,
    required this.tripId,
    this.groupId = '',
    this.tripStartDate,
    required this.items,
    this.locations = const [],
    this.onLocationCreated,
    this.onLocationDeleted,
    this.isTestEnvironment = false,
    required this.onChanged,
    this.onClose,
  });

  final String? tripId;
  final String groupId;
  final DateTime? tripStartDate;
  final List<ItineraryItemDto> items;
  final List<LocationDto> locations;
  final ItineraryLocationCreated? onLocationCreated;
  final Future<void> Function(LocationDto location)? onLocationDeleted;
  final bool isTestEnvironment;
  final ValueChanged<List<ItineraryItemDto>> onChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final itemsState = useState<List<ItineraryItemDto>>(
      sortItineraryItems(items),
    );
    final collapsedDateGroupKeys = useState<Set<String>>({});
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
      nameController.clear();
    }

    void deleteItem(ItineraryItemDto item) {
      notifyChange(
        itemsState.value.where((current) => current.id != item.id).toList(),
      );
    }

    void toggleDateGroup(String groupKey) {
      final next = Set<String>.from(collapsedDateGroupKeys.value);
      if (next.contains(groupKey)) {
        next.remove(groupKey);
      } else {
        next.add(groupKey);
      }
      collapsedDateGroupKeys.value = next;
    }

    Future<void> showEditBottomSheet(ItineraryItemDto item) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return ItineraryItemEditBottomSheet(
            key: const Key('itinerary_edit_bottom_sheet'),
            item: item,
            groupId: groupId,
            tripStartDate: tripStartDate,
            locations: locations,
            onLocationCreated: onLocationCreated,
            onLocationUnassigned: onLocationDeleted,
            otherLocationIds: itemsState.value
                .where((current) => current.id != item.id)
                .map((current) => current.locationId)
                .whereType<String>()
                .toSet(),
            isTestEnvironment: isTestEnvironment,
            onSaved: (updatedItem) {
              final previousLocation =
                  item.location ?? findLocationById(locations, item.locationId);
              final updated = List<ItineraryItemDto>.from(itemsState.value);
              final index = updated.indexWhere(
                (current) => current.id == updatedItem.id,
              );
              if (index == -1) {
                return;
              }
              updated[index] = updatedItem;
              if (previousLocation != null &&
                  previousLocation.id != updatedItem.locationId) {
                final isUsedByOtherItem = updated.any(
                  (current) => current.locationId == previousLocation.id,
                );
                if (!isUsedByOtherItem) {
                  onLocationDeleted?.call(previousLocation);
                }
              }
              notifyChange(updated);
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

    String timeLabel(ItineraryItemDto item) {
      return formatDateTimeRange(item);
    }

    List<String> subtitleParts(ItineraryItemDto item) {
      final location =
          item.location ?? findLocationById(locations, item.locationId);
      final locationName = location?.name;
      return <String>[
        if (locationName?.isNotEmpty == true) locationName!,
        if (item.memo?.isNotEmpty == true) item.memo!,
      ];
    }

    return Column(
      key: const Key('itinerary_view_root'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildHeader(),
        const SizedBox(height: 12),
        buildErrorBanner(),
        if (errorMessage.value != null) const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('itinerary_name_field'),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '項目名',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: addItem, child: const Text('追加')),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ItineraryList(
            items: itemsState.value,
            collapsedDateGroupKeys: collapsedDateGroupKeys.value,
            timeLabelBuilder: timeLabel,
            subtitleBuilder: subtitleParts,
            onToggleDateGroup: toggleDateGroup,
            onTapItem: (item) => showEditBottomSheet(item),
            onDeleteItem: deleteItem,
          ),
        ),
      ],
    );
  }
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

String formatTimeLabel(DateTime dateTime) {
  return [
    dateTime.hour.toString().padLeft(2, '0'),
    ':',
    dateTime.minute.toString().padLeft(2, '0'),
  ].join();
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String formatDateTimeRange(ItineraryItemDto item) {
  if (item.startDateTime != null && item.endDateTime != null) {
    final startDateTime = item.startDateTime!;
    final endDateTime = item.endDateTime!;
    final endLabel = isSameDate(startDateTime, endDateTime)
        ? formatTimeLabel(endDateTime)
        : formatDateTimeLabel(endDateTime);
    return '${formatTimeLabel(startDateTime)} - $endLabel';
  }
  if (item.startDateTime != null) {
    return formatTimeLabel(item.startDateTime!);
  }
  if (item.endDateTime != null) {
    return '終了: ${formatDateTimeLabel(item.endDateTime!)}';
  }
  return '';
}
