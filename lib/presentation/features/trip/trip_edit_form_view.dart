import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/map_views/map_view_factory.dart';
import 'package:uuid/uuid.dart';

typedef TripLocationCreated =
    Future<LocationDto> Function(LocationDto location);

class TripEditFormView extends HookWidget {
  const TripEditFormView({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onItineraryManagementRequested,
    required this.onTaskManagementRequested,
    this.locations = const [],
    this.onLocationCreated,
    this.onLocationDeleted,
    this.isTestEnvironment = false,
    this.configuredYear,
    this.clock,
  });

  final TripEntryDto value;
  final ValueChanged<TripEntryDto> onChanged;
  final VoidCallback onItineraryManagementRequested;
  final VoidCallback onTaskManagementRequested;
  final List<LocationDto> locations;
  final TripLocationCreated? onLocationCreated;
  final Future<void> Function(LocationDto location)? onLocationDeleted;
  final bool isTestEnvironment;
  final int? configuredYear;
  final AppClock? clock;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: value.name ?? '');
    final memoController = useTextEditingController(text: value.memo ?? '');
    final valueRef = useRef(value);
    final onChangedRef = useRef(onChanged);
    final startDate = useState<DateTime?>(value.startDate);
    final endDate = useState<DateTime?>(value.endDate);
    final isSyncingFromValueRef = useRef(false);
    final scrollController = useScrollController();
    final selectedTripLocation = useState<LocationDto?>(null);
    final effectiveClock = clock ?? NtpSynchronizedAppClock();

    TripEntryDto buildCurrentValue() {
      final normalizedTripName = nameController.text.isEmpty
          ? null
          : nameController.text;
      return valueRef.value.copyWith(
        name: normalizedTripName,
        startDate: startDate.value,
        endDate: endDate.value,
        memo: memoController.text,
      );
    }

    void notifyChanged() {
      if (isSyncingFromValueRef.value) {
        return;
      }

      final currentValue = buildCurrentValue();
      if (currentValue != valueRef.value) {
        onChangedRef.value(currentValue);
      }
    }

    void syncFromValue() {
      isSyncingFromValueRef.value = true;
      try {
        final name = value.name ?? '';
        if (nameController.text != name) {
          nameController.text = name;
        }

        final memo = value.memo ?? '';
        if (memoController.text != memo) {
          memoController.text = memo;
        }

        if (startDate.value != value.startDate) {
          startDate.value = value.startDate;
        }
        if (endDate.value != value.endDate) {
          endDate.value = value.endDate;
        }
      } finally {
        isSyncingFromValueRef.value = false;
      }
    }

    useEffect(() {
      valueRef.value = value;
      onChangedRef.value = onChanged;
      return null;
    }, [value, onChanged]);

    useEffect(() {
      syncFromValue();
      return null;
    }, [value]);

    useEffect(() {
      void listener() => notifyChanged();
      nameController.addListener(listener);
      memoController.addListener(listener);
      return () {
        nameController.removeListener(listener);
        memoController.removeListener(listener);
      };
    }, [nameController, memoController]);

    DateTime determineInitialDate(
      DateTime? selectedDate, {
      required bool isEndDate,
    }) {
      if (selectedDate != null) {
        return selectedDate;
      }

      if (isEndDate && startDate.value != null) {
        return DateTime(startDate.value!.year, startDate.value!.month, 1);
      }

      if (configuredYear != null) {
        return DateTime(configuredYear!, 1, 1);
      }

      return effectiveClock.now();
    }

    LocationDto buildLocation({required Coordinate coordinate, String? name}) {
      return LocationDto(
        id: const Uuid().v7(),
        tripId: value.id,
        groupId: value.groupId,
        name: name,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );
    }

    Future<LocationDto> createLocationFromCoordinate(
      Coordinate coordinate,
    ) async {
      final location = buildLocation(coordinate: coordinate);
      final createdLocation = await onLocationCreated?.call(location);
      final result = createdLocation ?? location;
      selectedTripLocation.value = result;
      return result;
    }

    Future<LocationDto> createLocationFromCandidate(
      LocationCandidateDto candidate,
    ) async {
      final location = buildLocation(
        coordinate: candidate.coordinate,
        name: candidate.name,
      );
      final createdLocation = await onLocationCreated?.call(location);
      final result = createdLocation ?? location;
      selectedTripLocation.value = result;
      return result;
    }

    Widget buildTripLocationsMap() {
      if (onLocationCreated == null && onLocationDeleted == null) {
        return const SizedBox.shrink();
      }

      final mapViewType = isTestEnvironment
          ? MapViewType.placeholder
          : MapViewType.google;
      List<String> itineraryNamesForLocation(LocationDto location) {
        return (value.itineraryItems ?? const [])
            .where((item) => item.locationId == location.id)
            .map((item) => item.name)
            .toList();
      }

      Widget buildSelectedLocationDetail(
        LocationDto location,
        VoidCallback onClose,
        Future<void> Function(LocationDto location) onLocationNameUpdated,
        Future<void> Function(LocationDto location) onLocationDeletedFromMap,
      ) {
        final linkedItineraryNames = itineraryNamesForLocation(location);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Container(
                key: const Key('trip_location_detail_panel'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: '閉じる',
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('trip_location_name_${location.id}'),
                          initialValue: location.name ?? '',
                          decoration: const InputDecoration(
                            labelText: '場所名',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            unawaited(
                              onLocationNameUpdated(
                                location.copyWith(
                                  name: value.trim().isEmpty
                                      ? null
                                      : value.trim(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          linkedItineraryNames.isEmpty
                              ? '関連する旅程なし'
                              : '関連する旅程: ${linkedItineraryNames.join(', ')}',
                        ),
                        if (linkedItineraryNames.isEmpty &&
                            onLocationDeleted != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await onLocationDeletedFromMap(location);
                                onClose();
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('削除'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      Future<void> showExpandedMap() async {
        var dialogLocations = List<LocationDto>.from(locations);
        await showDialog<void>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                Widget createDialogMap() {
                  return MapViewFactory.create(mapViewType).createMapView(
                    locations: dialogLocations,
                    onMapLongTapped: onLocationCreated == null
                        ? null
                        : (coordinate) async {
                            final location = await createLocationFromCoordinate(
                              coordinate,
                            );
                            setDialogState(() {
                              dialogLocations = [...dialogLocations, location];
                            });
                          },
                    onSearchedLocationSelected: onLocationCreated == null
                        ? null
                        : (candidate) async {
                            final location = await createLocationFromCandidate(
                              candidate,
                            );
                            setDialogState(() {
                              dialogLocations = [...dialogLocations, location];
                            });
                          },
                    onLocationTapped: (location) {
                      selectedTripLocation.value = location;
                      setDialogState(() {});
                    },
                    selectedLocation: selectedTripLocation.value,
                    locationDetailBuilder: (location, onClose) {
                      return buildSelectedLocationDetail(
                        location,
                        onClose,
                        (updatedLocation) async {
                          final savedLocation =
                              await onLocationCreated?.call(updatedLocation) ??
                              updatedLocation;
                          selectedTripLocation.value = savedLocation;
                          setDialogState(() {
                            dialogLocations = [
                              for (final current in dialogLocations)
                                current.id == savedLocation.id
                                    ? savedLocation
                                    : current,
                            ];
                          });
                        },
                        (deletedLocation) async {
                          await onLocationDeleted?.call(deletedLocation);
                          selectedTripLocation.value = null;
                          setDialogState(() {
                            dialogLocations = dialogLocations
                                .where(
                                  (current) => current.id != deletedLocation.id,
                                )
                                .toList();
                          });
                        },
                      );
                    },
                    tripStartDate: value.startDate,
                  );
                }

                return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  shape: const RoundedRectangleBorder(),
                  child: SizedBox(
                    key: const Key('trip_locations_expanded_map'),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: '閉じる',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        Expanded(child: createDialogMap()),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          key: const Key('trip_locations_button'),
          onPressed: showExpandedMap,
          icon: const Icon(Icons.place),
          label: const Text('訪問場所'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      );
    }

    Widget buildDatePickerField({
      required String labelText,
      required DateTime? selectedDate,
      required bool isEndDate,
      required ValueChanged<DateTime> onDateSelected,
      VoidCallback? onClear,
      String? clearTooltip,
    }) {
      return InkWell(
        onTap: () async {
          final date = await DatePickerHelper.showCustomDatePicker(
            context,
            initialDate: determineInitialDate(
              selectedDate,
              isEndDate: isEndDate,
            ),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            onDateSelected(date);
            notifyChanged();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate != null
                      ? '${selectedDate.year}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}'
                      : labelText,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedDate != null && onClear != null)
                    Tooltip(
                      message: clearTooltip ?? '日付をクリア',
                      child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        splashRadius: 18,
                        onPressed: onClear,
                      ),
                    ),
                  const Icon(Icons.calendar_today, color: Colors.black54),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '旅行名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              buildDatePickerField(
                labelText: '旅行期間 From',
                selectedDate: startDate.value,
                isEndDate: false,
                onDateSelected: (date) => startDate.value = date,
                onClear: () {
                  startDate.value = null;
                  notifyChanged();
                },
                clearTooltip: '旅行開始日をクリア',
              ),
              const SizedBox(height: 16),
              buildDatePickerField(
                labelText: '旅行期間 To',
                selectedDate: endDate.value,
                isEndDate: true,
                onDateSelected: (date) => endDate.value = date,
                onClear: () {
                  endDate.value = null;
                  notifyChanged();
                },
                clearTooltip: '旅行終了日をクリア',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: memoController,
            decoration: const InputDecoration(
              labelText: 'メモ',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onItineraryManagementRequested,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.event_note, size: 20),
                      SizedBox(width: 4),
                      Text('旅程'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTaskManagementRequested,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.checklist, size: 20),
                      SizedBox(width: 4),
                      Text('タスク'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildTripLocationsMap(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
