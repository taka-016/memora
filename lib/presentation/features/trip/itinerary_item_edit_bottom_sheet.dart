import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:memora/presentation/shared/sheets/bottom_sheet_content_padding.dart';
import 'package:uuid/uuid.dart';

typedef ItineraryLocationCreated =
    Future<LocationDto> Function(LocationDto location);

class ItineraryItemEditBottomSheet extends HookWidget {
  const ItineraryItemEditBottomSheet({
    super.key,
    required this.item,
    required this.groupId,
    this.tripStartDate,
    this.locations = const [],
    this.onLocationCreated,
    this.onLocationUnassigned,
    this.isTestEnvironment = false,
    required this.onSaved,
    this.clock,
  });

  final ItineraryItemDto item;
  final String groupId;
  final DateTime? tripStartDate;
  final List<LocationDto> locations;
  final ItineraryLocationCreated? onLocationCreated;
  final Future<void> Function(LocationDto location)? onLocationUnassigned;
  final bool isTestEnvironment;
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
    final selectedLocation = useState<LocationDto?>(
      item.location ?? findLocationById(locations, item.locationId),
    );
    final isLocationMapVisible = useState(false);
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

    LocationDto buildLocation({required Coordinate coordinate, String? name}) {
      return LocationDto(
        id: const Uuid().v7(),
        tripId: item.tripId,
        groupId: groupId,
        name: name,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );
    }

    Future<void> selectCreatedLocation(LocationDto location) async {
      final savedLocation = await onLocationCreated?.call(location);
      selectedLocation.value = savedLocation ?? location;
      isLocationMapVisible.value = false;
    }

    Future<void> createLocationFromCoordinate(Coordinate coordinate) async {
      await selectCreatedLocation(buildLocation(coordinate: coordinate));
    }

    Future<void> createLocationFromCandidate(
      LocationCandidateDto candidate,
    ) async {
      await selectCreatedLocation(
        buildLocation(coordinate: candidate.coordinate, name: candidate.name),
      );
    }

    Future<void> clearLocation() async {
      final location = selectedLocation.value;
      selectedLocation.value = null;
      isLocationMapVisible.value = false;
      if (location != null) {
        await onLocationUnassigned?.call(location);
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
        selectedLocation: selectedLocation.value,
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

    String locationName(LocationDto location) {
      return location.name?.isNotEmpty == true ? location.name! : '場所名未設定';
    }

    Widget buildLocationSection() {
      final location = selectedLocation.value;
      final hasMapCallbacks = locations.isNotEmpty || onLocationCreated != null;
      if (location == null && !hasMapCallbacks) {
        return const SizedBox.shrink();
      }
      final mapViewType = isTestEnvironment
          ? MapViewType.placeholder
          : MapViewType.google;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location == null)
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: hasMapCallbacks
                    ? () => isLocationMapVisible.value = true
                    : null,
                icon: const Icon(Icons.place),
                label: const Text('場所を指定'),
              ),
            )
          else ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => isLocationMapVisible.value = true,
                  icon: const Icon(Icons.place),
                  label: const Text('場所を変更'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: clearLocation,
                  icon: const Icon(Icons.clear),
                  label: const Text('指定を解除'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(locationName(location)),
            ),
          ],
          if (isLocationMapVisible.value) ...[
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('itinerary_location_map'),
              height: 240,
              width: double.infinity,
              child: MapViewFactory.create(mapViewType).createMapView(
                locations: locations,
                selectedLocation: selectedLocation.value,
                highlightSelectedLocation: true,
                onLocationTapped: (location) {
                  selectedLocation.value = location;
                  isLocationMapVisible.value = false;
                },
                onMapLongTapped: onLocationCreated == null
                    ? null
                    : createLocationFromCoordinate,
                onSearchedLocationSelected: onLocationCreated == null
                    ? null
                    : createLocationFromCandidate,
              ),
            ),
          ],
        ],
      );
    }

    return Padding(
      key: const Key('itinerary_edit_bottom_sheet_content_padding'),
      padding: bottomSheetContentPadding(context),
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
            const SizedBox(height: 12),
            buildLocationSection(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: save, child: const Text('保存')),
              ],
            ),
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
  LocationDto? selectedLocation,
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
      locationId: selectedLocation?.id,
      location: selectedLocation,
    ),
  );
}

LocationDto? findLocationById(List<LocationDto> locations, String? locationId) {
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
