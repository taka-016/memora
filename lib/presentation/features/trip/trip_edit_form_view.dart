import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';

class TripEditFormView extends HookWidget {
  const TripEditFormView({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onTaskManagementRequested,
    required this.onVisitLocationEditRequested,
    required this.onRouteInfoRequested,
    this.configuredYear,
  });

  final TripEntryDto value;
  final ValueChanged<TripEntryDto> onChanged;
  final VoidCallback onTaskManagementRequested;
  final VoidCallback onVisitLocationEditRequested;
  final VoidCallback onRouteInfoRequested;
  final int? configuredYear;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: value.tripName ?? '');
    final memoController = useTextEditingController(text: value.tripMemo ?? '');
    final valueRef = useRef(value);
    final onChangedRef = useRef(onChanged);
    final startDate = useState<DateTime?>(value.tripStartDate);
    final endDate = useState<DateTime?>(value.tripEndDate);
    final pins = useState<List<PinDto>>(
      List<PinDto>.from(value.pins ?? const []),
    );
    final selectedPin = useState<PinDto?>(null);
    final isBottomSheetVisible = useState(false);
    final isSyncingFromValueRef = useRef(false);
    final scrollController = useScrollController();

    TripEntryDto buildCurrentValue() {
      final normalizedTripName = nameController.text.isEmpty
          ? null
          : nameController.text;
      return valueRef.value.copyWith(
        tripName: normalizedTripName,
        tripStartDate: startDate.value,
        tripEndDate: endDate.value,
        tripMemo: memoController.text,
        pins: List<PinDto>.from(pins.value),
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
        final tripName = value.tripName ?? '';
        if (nameController.text != tripName) {
          nameController.text = tripName;
        }

        final tripMemo = value.tripMemo ?? '';
        if (memoController.text != tripMemo) {
          memoController.text = tripMemo;
        }

        if (startDate.value != value.tripStartDate) {
          startDate.value = value.tripStartDate;
        }
        if (endDate.value != value.tripEndDate) {
          endDate.value = value.tripEndDate;
        }

        final nextPins = List<PinDto>.from(value.pins ?? const []);
        if (!listEquals(pins.value, nextPins)) {
          pins.value = nextPins;
        }

        final currentSelectedPin = selectedPin.value;
        if (currentSelectedPin != null) {
          final matchingPins = nextPins.where(
            (pin) => pin.pinId == currentSelectedPin.pinId,
          );
          if (matchingPins.isEmpty) {
            isBottomSheetVisible.value = false;
            selectedPin.value = null;
          } else {
            final nextSelectedPin = matchingPins.first;
            if (nextSelectedPin != currentSelectedPin) {
              selectedPin.value = nextSelectedPin;
            }
          }
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

    void hideBottomSheet() {
      isBottomSheetVisible.value = false;
      selectedPin.value = null;
    }

    void handlePinTapped(PinDto pin) {
      selectedPin.value = pin;
      isBottomSheetVisible.value = true;
    }

    void handlePinDeleted(String pinId) {
      pins.value = pins.value.where((pin) => pin.pinId != pinId).toList();
      if (selectedPin.value?.pinId == pinId) {
        selectedPin.value = null;
      }
      hideBottomSheet();
      notifyChanged();
    }

    void handlePinUpdated(PinDto pin) {
      final updatedPins = List<PinDto>.from(pins.value);
      final index = updatedPins.indexWhere(
        (current) => current.pinId == pin.pinId,
      );
      if (index == -1) {
        return;
      }
      updatedPins[index] = pin;
      pins.value = updatedPins;
      hideBottomSheet();
      notifyChanged();
    }

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

      return DateTime.now();
    }

    String formatDateTime(DateTime dateTime) {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    }

    Widget buildBottomSheet() {
      if (!isBottomSheetVisible.value || selectedPin.value == null) {
        return const SizedBox.shrink();
      }

      return PinDetailBottomSheet(
        pin: selectedPin.value!,
        onUpdate: handlePinUpdated,
        onDelete: handlePinDeleted,
        onClose: hideBottomSheet,
      );
    }

    Widget buildPinsList() {
      if (pins.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(pins.value.length, (index) {
            final pin = pins.value[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: ListTile(
                key: Key('pinListItem_${pin.pinId}'),
                dense: true,
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                title: Text(
                  pin.locationName?.isNotEmpty == true ? pin.locationName! : '',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: () {
                  final subtitleParts = <String>[];
                  if (pin.visitStartDate != null && pin.visitEndDate != null) {
                    subtitleParts.add(
                      '${formatDateTime(pin.visitStartDate!)} - ${formatDateTime(pin.visitEndDate!)}',
                    );
                  } else if (pin.visitStartDate != null) {
                    subtitleParts.add(
                      '開始: ${formatDateTime(pin.visitStartDate!)}',
                    );
                  } else if (pin.visitEndDate != null) {
                    subtitleParts.add(
                      '終了: ${formatDateTime(pin.visitEndDate!)}',
                    );
                  }

                  if (subtitleParts.isEmpty) {
                    return null;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subtitleParts
                        .map(
                          (text) =>
                              Text(text, style: const TextStyle(fontSize: 12)),
                        )
                        .toList(),
                  );
                }(),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => handlePinDeleted(pin.pinId),
                ),
                onTap: () => handlePinTapped(pin),
              ),
            );
          }),
        ],
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

    return Stack(
      children: [
        SingleChildScrollView(
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
              SizedBox(
                width: double.infinity,
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
                      Text('タスク管理'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '訪問場所',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onVisitLocationEditRequested,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_location, size: 20),
                          SizedBox(width: 4),
                          Text('編集'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: pins.value.length >= 2
                          ? onRouteInfoRequested
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.route, size: 20),
                          SizedBox(width: 4),
                          Text('経路情報'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              buildPinsList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        buildBottomSheet(),
      ],
    );
  }
}
