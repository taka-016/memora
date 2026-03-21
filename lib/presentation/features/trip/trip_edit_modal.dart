import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';
import 'package:memora/presentation/notifiers/edit_state_notifier.dart';
import 'package:memora/presentation/features/trip/route_info_view.dart';
import 'package:memora/presentation/features/trip/select_visit_location_view.dart';
import 'package:memora/presentation/features/trip/task_view.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_confirm_dialog.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

enum TripEditExpandedSection { map, routeInfo, tasks }

class TripEditModalTestHandle {
  void Function(DateTime?, DateTime?)? _setDateRange;
  void Function(List<PinDto>)? _setPins;

  @visibleForTesting
  void setDateRangeForTest(DateTime? start, DateTime? end) {
    _setDateRange?.call(start, end);
  }

  @visibleForTesting
  void setPinsForTest(List<PinDto> pins) {
    _setPins?.call(pins);
  }
}

class TripEditModal extends HookConsumerWidget {
  final String groupId;
  final List<GroupMemberDto> groupMembers;
  final TripEntryDto? tripEntry;
  final Future<void> Function(TripEntryDto) onSave;
  final bool isTestEnvironment;
  final int? year;
  final TripEditModalTestHandle? testHandle;
  final NearbyLocationService? nearbyLocationService;

  const TripEditModal({
    super.key,
    required this.groupId,
    required this.groupMembers,
    this.tripEntry,
    required this.onSave,
    this.isTestEnvironment = false,
    this.year,
    this.testHandle,
    this.nearbyLocationService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final initialPins = useMemoized(
      () => List<PinDto>.from(tripEntry?.pins ?? []),
      [tripEntry],
    );
    final initialTasks = useMemoized(
      () => List<TaskDto>.from(tripEntry?.tasks ?? []),
      [tripEntry],
    );
    final pins = useState<List<PinDto>>(initialPins);
    final tasks = useState<List<TaskDto>>(initialTasks);
    final selectedPin = useState<PinDto?>(null);
    final isBottomSheetVisible = useState(false);
    final scrollController = useScrollController();
    final mapIconKey = useMemoized(() => GlobalKey());
    final editStateNotifier = ref.read(editStateNotifierProvider.notifier);
    final editState = ref.watch(editStateNotifierProvider);
    final internalNearbyLocationService = useMemoized(
      () => nearbyLocationService == null
          ? GooglePlacesApiNearbyLocationService(apiKey: Env.googlePlacesApiKey)
          : null,
      [nearbyLocationService],
    );
    final effectiveNearbyLocationService =
        nearbyLocationService ?? internalNearbyLocationService;

    final initialTripForComparison = useMemoized(() {
      final tripYearValue = tripEntry?.tripYear ?? year ?? DateTime.now().year;
      return TripEntryDto(
        id: tripEntry?.id ?? '',
        groupId: groupId,
        tripYear: tripYearValue,
        tripName: tripEntry?.tripName,
        tripStartDate: tripEntry?.tripStartDate,
        tripEndDate: tripEntry?.tripEndDate,
        tripMemo: tripEntry?.tripMemo ?? '',
        pins: initialPins,
        tasks: initialTasks,
      );
    }, [groupId, tripEntry, year]);

    TripEntryDto buildUpdatedTripEntry() {
      final tripName = nameController.text.isEmpty ? null : nameController.text;
      return initialTripForComparison.copyWith(
        tripName: tripName,
        tripStartDate: startDate.value,
        tripEndDate: endDate.value,
        tripMemo: memoController.text,
        pins: List<PinDto>.from(pins.value),
        tasks: List<TaskDto>.from(tasks.value),
      );
    }

    void updateDirtyState() {
      final isDirty = buildUpdatedTripEntry() != initialTripForComparison;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editStateNotifier.setDirty(isDirty);
      });
    }

    useEffect(() {
      void listener() => updateDirtyState();
      nameController.addListener(listener);
      memoController.addListener(listener);
      return () {
        nameController.removeListener(listener);
        memoController.removeListener(listener);
      };
    }, [nameController, memoController]);

    useEffect(() {
      updateDirtyState();
      return null;
    }, [startDate.value, endDate.value, pins.value, tasks.value]);

    useEffect(() {
      return () {
        internalNearbyLocationService?.httpClient.close();
      };
    }, [internalNearbyLocationService]);

    void hideBottomSheet() {
      isBottomSheetVisible.value = false;
      selectedPin.value = null;
    }

    void addPin({required Coordinate coordinate, String? locationName}) {
      final uuid = Uuid();
      final pinId = uuid.v4();
      final newPin = PinDto(
        pinId: pinId,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        locationName: locationName,
      );

      pins.value = [...pins.value, newPin];
      selectedPin.value = newPin;
    }

    Future<String?> getLocationName(Coordinate coordinate) async {
      try {
        return await effectiveNearbyLocationService!.getLocationName(
          coordinate,
        );
      } catch (e, stack) {
        logger.e(
          'TripEditModal.getLocationName: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
        return null;
      }
    }

    Future<void> handleMapLongTapped(Coordinate coordinate) async {
      final locationName = await getLocationName(coordinate);
      addPin(coordinate: coordinate, locationName: locationName);
    }

    void handleSearchedLocationSelected(LocationCandidateDto candidate) {
      addPin(coordinate: candidate.coordinate, locationName: candidate.name);
    }

    useEffect(() {
      if (testHandle != null) {
        testHandle!._setDateRange = (DateTime? start, DateTime? end) {
          startDate.value = start;
          endDate.value = end;
        };
        testHandle!._setPins = (List<PinDto> newPins) {
          pins.value = List<PinDto>.from(newPins);
        };
      }
      return () {
        if (testHandle != null) {
          testHandle!._setDateRange = null;
          testHandle!._setPins = null;
        }
      };
    }, [testHandle]);

    void handlePinTapped(PinDto pin) {
      selectedPin.value = pin;
    }

    void handlePinDeleted(String pinId) {
      pins.value = pins.value.where((pin) => pin.pinId != pinId).toList();
      if (selectedPin.value?.pinId == pinId) {
        selectedPin.value = null;
      }
      hideBottomSheet();
    }

    void handlePinUpdated(PinDto pin) {
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

    void showTaskView() {
      expandedSection.value = TripEditExpandedSection.tasks;
      hideBottomSheet();
    }

    void closeRouteInfoView() {
      expandedSection.value = null;
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
          final sortedTasks = List<TaskDto>.from(tasks.value)
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          final updatedTripEntry = buildUpdatedTripEntry().copyWith(
            tripStartDate: selectedStart,
            tripEndDate: selectedEnd,
            tasks: sortedTasks,
          );
          await onSave(updatedTripEntry);
          editStateNotifier.reset();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } on ApplicationValidationException catch (e) {
          errorMessage.value = e.message;
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

    Widget buildNormalLayout() {
      return Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TripEditFormView(
                  formKey: formKey,
                  scrollController: scrollController,
                  titleText: tripEntry != null ? '旅行編集' : '旅行新規作成',
                  nameController: nameController,
                  memoController: memoController,
                  startDate: startDate.value,
                  endDate: endDate.value,
                  errorMessage: errorMessage.value,
                  configuredYear: tripEntry?.tripYear ?? year,
                  pins: pins.value,
                  mapButtonKey: mapIconKey,
                  onStartDateSelected: (date) {
                    startDate.value = date;
                    errorMessage.value = null;
                  },
                  onEndDateSelected: (date) {
                    endDate.value = date;
                    errorMessage.value = null;
                  },
                  onStartDateCleared: () {
                    startDate.value = null;
                    errorMessage.value = null;
                  },
                  onEndDateCleared: () {
                    endDate.value = null;
                    errorMessage.value = null;
                  },
                  onShowTaskView: showTaskView,
                  onToggleMapExpansion: toggleMapExpansion,
                  onShowRouteInfoView: showRouteInfoView,
                  onPinTapped: (pin) {
                    handlePinTapped(pin);
                    isBottomSheetVisible.value = true;
                  },
                  onPinDeleted: handlePinDeleted,
                  canShowRouteInfo: pins.value.length >= 2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      if (!editState.isDirty) {
                        editStateNotifier.reset();
                        Navigator.of(context).pop();
                        return;
                      }

                      final shouldClose = await EditDiscardConfirmDialog.show(
                        context,
                      );
                      if (!context.mounted) {
                        return;
                      }

                      if (shouldClose) {
                        editStateNotifier.reset();
                        Navigator.of(context).pop();
                      }
                    },
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
            onMapLongTapped: handleMapLongTapped,
            onSearchedLocationSelected: handleSearchedLocationSelected,
            onPinTapped: handlePinTapped,
            onPinUpdated: handlePinUpdated,
            onPinDeleted: handlePinDeleted,
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
            tripId: tripEntry?.id,
            tasks: tasks.value,
            groupMembers: groupMembers,
            onChanged: (updatedTasks) {
              tasks.value = List<TaskDto>.from(updatedTasks);
            },
            onClose: () => expandedSection.value = null,
          );
        default:
          return buildNormalLayout();
      }
    }

    return PopScope(
      canPop: !editState.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          editStateNotifier.reset();
          return;
        }
        final shouldClose = await EditDiscardConfirmDialog.show(context);
        if (!context.mounted) {
          return;
        }
        if (shouldClose) {
          editStateNotifier.reset();
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
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
      ),
    );
  }
}
