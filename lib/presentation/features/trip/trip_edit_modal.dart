import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';
import 'package:memora/domain/value_objects/location.dart';
import 'package:memora/presentation/helpers/date_picker_helper.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';
import 'package:memora/presentation/features/trip/task_view.dart';
import 'package:memora/presentation/features/trip/route_info_view.dart';
import 'package:memora/presentation/features/trip/select_visit_location_view.dart';
import 'package:uuid/uuid.dart';

enum TripEditExpandedSection { map, routeInfo, tasks }

class TripEditModalTestHandle {
  void Function(DateTime?, DateTime?)? _setDateRange;
  void Function(List<PinDto>)? _setPins;
  void Function(List<Task>)? _setTasks;

  @visibleForTesting
  void setDateRangeForTest(DateTime? start, DateTime? end) {
    _setDateRange?.call(start, end);
  }

  @visibleForTesting
  void setPinsForTest(List<PinDto> pins) {
    _setPins?.call(pins);
  }

  @visibleForTesting
  void setTasksForTest(List<Task> tasks) {
    _setTasks?.call(tasks);
  }
}

class TripEditModal extends HookWidget {
  final String groupId;
  final TripEntryDto? tripEntry;
  final Function(TripEntry) onSave;
  final bool isTestEnvironment;
  final int? year;
  final TripEditModalTestHandle? testHandle;
  final List<GroupMemberDto> assignableMembers;

  const TripEditModal({
    super.key,
    required this.groupId,
    this.tripEntry,
    required this.onSave,
    this.isTestEnvironment = false,
    this.year,
    this.testHandle,
    this.assignableMembers = const [],
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(
      text: tripEntry?.tripName ?? '',
    );
    final memoController = useTextEditingController(
      text: tripEntry?.tripMemo ?? '',
    );
    final startDate = useState<DateTime?>(tripEntry?.tripStartDate);
    final endDate = useState<DateTime?>(tripEntry?.tripEndDate);
    final errorMessage = useState<String?>(null);
    final expandedSection = useState<TripEditExpandedSection?>(null);
    final pins = useState<List<PinDto>>(
      List<PinDto>.from(tripEntry?.pins ?? []),
    );
    final tasks = useState<List<EditableTask>>(() {
      final dtoTasks = tripEntry?.tasks ?? <TaskDto>[];
      return dtoTasks
          .map(
            (taskDto) => EditableTask(
              id: taskDto.id,
              task: TaskMapper.toEntity(taskDto),
            ),
          )
          .toList();
    }());
    final selectedPin = useState<PinDto?>(null);
    final isBottomSheetVisible = useState(false);
    final scrollController = useScrollController();
    final mapIconKey = useMemoized(() => GlobalKey());

    useEffect(() {
      if (testHandle != null) {
        testHandle!._setDateRange = (DateTime? start, DateTime? end) {
          startDate.value = start;
          endDate.value = end;
        };
        testHandle!._setPins = (List<PinDto> newPins) {
          pins.value = List<PinDto>.from(newPins);
        };
        testHandle!._setTasks = (List<Task> newTasks) {
          tasks.value = newTasks
              .asMap()
              .entries
              .map(
                (entry) => EditableTask(
                  id: const Uuid().v4(),
                  task: entry.value.copyWith(orderIndex: entry.key),
                ),
              )
              .toList();
        };
      }
      return () {
        if (testHandle != null) {
          testHandle!._setDateRange = null;
          testHandle!._setPins = null;
          testHandle!._setTasks = null;
        }
      };
    }, [testHandle]);

    void hideBottomSheet() {
      isBottomSheetVisible.value = false;
      selectedPin.value = null;
    }

    Future<void> onMapLongTapped(Location location) async {
      final uuid = Uuid();
      final pinId = uuid.v4();
      final newPin = PinDto(
        pinId: pinId,
        latitude: location.latitude,
        longitude: location.longitude,
      );

      pins.value = [...pins.value, newPin];
      selectedPin.value = newPin;
    }

    void onPinTapped(PinDto pin) {
      selectedPin.value = pin;
    }

    Future<void> onPinDeleted(String pinId) async {
      pins.value = pins.value.where((pin) => pin.pinId != pinId).toList();
      if (selectedPin.value?.pinId == pinId) {
        selectedPin.value = null;
      }
      hideBottomSheet();
    }

    void onPinUpdated(PinDto pin) {
      final updatedPins = List<PinDto>.from(pins.value);
      final index = updatedPins.indexWhere((p) => p.pinId == pin.pinId);
      if (index != -1) {
        updatedPins[index] = pin;
        pins.value = updatedPins;
      }
      hideBottomSheet();
    }

    void toggleMapExpansion() {
      if (expandedSection.value == TripEditExpandedSection.map) {
        expandedSection.value = null;
        hideBottomSheet();
      } else {
        expandedSection.value = TripEditExpandedSection.map;
      }
    }

    void showRouteInfoView() {
      if (pins.value.length < 2) {
        return;
      }
      expandedSection.value = TripEditExpandedSection.routeInfo;
      hideBottomSheet();
    }

    void closeRouteInfoView() {
      expandedSection.value = null;
    }

    void showTaskView() {
      expandedSection.value = TripEditExpandedSection.tasks;
      hideBottomSheet();
    }

    void closeTaskView() {
      expandedSection.value = null;
    }

    String formatDateTime(DateTime dateTime) {
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    }

    Future<void> handleSave() async {
      errorMessage.value = null;
      final selectedStart = startDate.value;
      final selectedEnd = endDate.value;
      final tripYearValue = tripEntry?.tripYear ?? year ?? DateTime.now().year;

      if (selectedStart != null &&
          selectedEnd != null &&
          selectedStart.isAfter(selectedEnd)) {
        errorMessage.value = '開始日は終了日より前の日付を選択してください';
        return;
      }

      if (selectedStart != null && selectedStart.year != tripYearValue) {
        errorMessage.value = '開始日は$tripYearValue年の日付を選択してください';
        return;
      }

      if (formKey.currentState!.validate()) {
        try {
          final taskEntities = tasks.value
              .asMap()
              .entries
              .map((entry) => entry.value.task.copyWith(orderIndex: entry.key))
              .toList();
          final trip = TripEntry(
            id: tripEntry?.id ?? '',
            groupId: groupId,
            tripYear: tripYearValue,
            tripName: nameController.text.isEmpty ? null : nameController.text,
            tripStartDate: selectedStart,
            tripEndDate: selectedEnd,
            tripMemo: memoController.text.isEmpty ? null : memoController.text,
            pins: PinMapper.toEntityList(pins.value),
            tasks: taskEntities,
          );
          onSave(trip);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } on ValidationException catch (e) {
          errorMessage.value = '$e';
        } catch (e, stack) {
          logger.e(
            'TripEditModal.handleSave: ${e.toString()}',
            error: e,
            stackTrace: stack,
          );
          errorMessage.value = 'エラーが発生しました: $e';
        }
      }
    }

    DateTime determineInitialDate(DateTime? selectedDate, String labelText) {
      if (selectedDate != null) {
        return selectedDate;
      }

      if (labelText == '旅行期間 To' && startDate.value != null) {
        return DateTime(startDate.value!.year, startDate.value!.month, 1);
      }

      final configuredYear = tripEntry?.tripYear ?? year;
      if (configuredYear != null) {
        return DateTime(configuredYear, 1, 1);
      }
      return DateTime.now();
    }

    Widget buildBottomSheet() {
      if (!isBottomSheetVisible.value || selectedPin.value == null) {
        return const SizedBox.shrink();
      }

      return PinDetailBottomSheet(
        pin: selectedPin.value!,
        onUpdate: onPinUpdated,
        onDelete: onPinDeleted,
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
                  final List<String> subtitleParts = [];
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
                  onPressed: () => onPinDeleted(pin.pinId),
                ),
                onTap: () {
                  onPinTapped(pin);
                  isBottomSheetVisible.value = true;
                },
              ),
            );
          }),
        ],
      );
    }

    Widget buildDatePickerField({
      required String labelText,
      required DateTime? selectedDate,
      required Function(DateTime) onDateSelected,
      VoidCallback? onClear,
      String? clearTooltip,
    }) {
      return InkWell(
        onTap: () async {
          final initialDate = determineInitialDate(selectedDate, labelText);
          final date = await DatePickerHelper.showCustomDatePicker(
            context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            onDateSelected(date);
            errorMessage.value = null;
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
                        onPressed: () {
                          onClear();
                          errorMessage.value = null;
                        },
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

    Widget buildNormalLayout() {
      return Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tripEntry != null ? '旅行編集' : '旅行新規作成',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (errorMessage.value != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              errorMessage.value!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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
                              onDateSelected: (date) => startDate.value = date,
                              onClear: () => startDate.value = null,
                              clearTooltip: '旅行開始日をクリア',
                            ),
                            const SizedBox(height: 16),
                            buildDatePickerField(
                              labelText: '旅行期間 To',
                              selectedDate: endDate.value,
                              onDateSelected: (date) => endDate.value = date,
                              onClear: () => endDate.value = null,
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
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '訪問場所',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ElevatedButton(
                                  key: mapIconKey,
                                  onPressed: toggleMapExpansion,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ElevatedButton(
                                  onPressed: pins.value.length >= 2
                                      ? showRouteInfoView
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: ElevatedButton(
                                  onPressed: showTaskView,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        buildPinsList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: handleSave,
                    child: Text(tripEntry != null ? '更新' : '作成'),
                  ),
                ],
              ),
            ],
          ),
          buildBottomSheet(),
        ],
      );
    }

    Widget buildDialogContent() {
      switch (expandedSection.value) {
        case TripEditExpandedSection.map:
          return SelectVisitLocationView(
            pins: pins.value,
            selectedPin: selectedPin.value,
            isTestEnvironment: isTestEnvironment,
            onClose: toggleMapExpansion,
            onMapLongTapped: onMapLongTapped,
            onMarkerTapped: onPinTapped,
            onMarkerUpdated: onPinUpdated,
            onMarkerDeleted: onPinDeleted,
            bottomSheet: buildBottomSheet(),
            closeButtonKey: mapIconKey,
          );
        case TripEditExpandedSection.routeInfo:
          return RouteInfoView(
            pins: pins.value,
            isTestEnvironment: isTestEnvironment,
            onClose: closeRouteInfoView,
          );
        case TripEditExpandedSection.tasks:
          return TaskView(
            tripId: tripEntry?.id ?? '',
            tasks: tasks.value,
            assignableMembers: assignableMembers,
            onChanged: (updated) => tasks.value = updated,
            onClose: closeTaskView,
          );
        default:
          return buildNormalLayout();
      }
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      child: Material(
        type: MaterialType.card,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24.0),
          child: buildDialogContent(),
        ),
      ),
    );
  }
}
