import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/presentation/features/trip/itinerary_item_edit_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/itinerary_list.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:uuid/uuid.dart';

class ItineraryView extends HookWidget {
  const ItineraryView({
    super.key,
    required this.tripId,
    this.tripStartDate,
    required this.items,
    this.locations = const [],
    required this.onChanged,
    this.onLocationsChanged,
    this.onClose,
    this.isTestEnvironment = false,
  });

  final String? tripId;
  final DateTime? tripStartDate;
  final List<ItineraryItemDto> items;
  final List<LocationDto> locations;
  final ValueChanged<List<ItineraryItemDto>> onChanged;
  final ValueChanged<List<LocationDto>>? onLocationsChanged;
  final VoidCallback? onClose;
  final bool isTestEnvironment;

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

    void updateItemLocation(ItineraryItemDto item, LocationDto? location) {
      final updated = itemsState.value.map((current) {
        if (current.id != item.id) {
          return current;
        }
        return current.copyWith(locationId: location?.id, location: location);
      }).toList();
      notifyChange(updated);
    }

    Future<LocationDto?> showLocationSelectionBottomSheet(
      BuildContext sheetContext,
      ItineraryItemDto item,
    ) async {
      final currentLocation =
          item.location ?? _locationById(locations, item.locationId);
      return showModalBottomSheet<LocationDto?>(
        context: sheetContext,
        isScrollControlled: true,
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ItineraryLocationSelectView(
                key: const Key('itinerary_location_select_view'),
                item: item,
                locations: locations,
                isTestEnvironment: isTestEnvironment,
                onMapLongTapped: (coordinate) {
                  final location = LocationDto(
                    id: const Uuid().v7(),
                    tripId: tripId ?? '',
                    groupId: locations.isNotEmpty
                        ? locations.first.groupId
                        : '',
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                  );
                  onLocationsChanged?.call([...locations, location]);
                  updateItemLocation(item, location);
                  Navigator.of(context).pop(location);
                },
                onLocationSelected: (location) {
                  updateItemLocation(item, location);
                  Navigator.of(context).pop(location);
                },
                onLocationCleared: () {
                  updateItemLocation(item, null);
                  Navigator.of(context).pop(null);
                },
                onClose: () => Navigator.of(context).pop(currentLocation),
              ),
            ),
          );
        },
      );
    }

    Future<void> showEditBottomSheet(ItineraryItemDto item) async {
      final itemLocation =
          item.location ?? _locationById(locations, item.locationId);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return ItineraryItemEditBottomSheet(
            key: const Key('itinerary_edit_bottom_sheet'),
            item: item,
            tripStartDate: tripStartDate,
            location: itemLocation,
            onLocationSelectionRequested: showLocationSelectionBottomSheet,
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
      return <String>[if (item.memo?.isNotEmpty == true) item.memo!];
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

LocationDto? _locationById(List<LocationDto> locations, String? locationId) {
  if (locationId == null) {
    return null;
  }
  for (final location in locations) {
    if (location.id == locationId) {
      return location;
    }
  }
  return null;
}

class ItineraryLocationSelectView extends StatelessWidget {
  const ItineraryLocationSelectView({
    super.key,
    required this.item,
    required this.locations,
    required this.onLocationSelected,
    required this.onLocationCleared,
    required this.onMapLongTapped,
    required this.onClose,
    this.isTestEnvironment = false,
  });

  final ItineraryItemDto item;
  final List<LocationDto> locations;
  final ValueChanged<LocationDto> onLocationSelected;
  final VoidCallback onLocationCleared;
  final ValueChanged<Coordinate> onMapLongTapped;
  final VoidCallback onClose;
  final bool isTestEnvironment;

  @override
  Widget build(BuildContext context) {
    final pins = locations
        .map(
          (location) => PinDto(
            pinId: location.id,
            tripId: location.tripId,
            groupId: location.groupId,
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: location.name,
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '場所を指定',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child:
                MapViewFactory.create(
                  isTestEnvironment
                      ? MapViewType.placeholder
                      : MapViewType.google,
                ).createMapView(
                  pins: pins,
                  onMapLongTapped: onMapLongTapped,
                  isReadOnly: true,
                  defaultMarkerHue: BitmapDescriptor.hueAzure,
                  highlightedPinIds: {
                    if (item.locationId != null) item.locationId!,
                  },
                  highlightedMarkerHue: BitmapDescriptor.hueRed,
                ),
          ),
        ),
        const SizedBox(height: 12),
        if (item.locationId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              key: const Key('clear_itinerary_location'),
              onPressed: onLocationCleared,
              icon: const Icon(Icons.link_off),
              label: const Text('紐付けを解除'),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: locations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final location = locations[index];
              final selected = location.id == item.locationId;
              return ListTile(
                key: Key('select_itinerary_location_${location.id}'),
                leading: Icon(
                  Icons.place,
                  color: selected ? Colors.red : Colors.grey,
                ),
                title: Text(location.name ?? '名称未設定'),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => onLocationSelected(location),
              );
            },
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
