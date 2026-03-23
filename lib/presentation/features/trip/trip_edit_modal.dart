import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/models/coordinate.dart';
import 'package:memora/domain/services/nearby_location_service.dart';
import 'package:memora/env/env.dart';
import 'package:memora/infrastructure/services/google_places_api_nearby_location_service.dart';
import 'package:memora/presentation/features/trip/route_info_view.dart';
import 'package:memora/presentation/features/trip/select_visit_location_view.dart';
import 'package:memora/presentation/features/trip/task_view.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';
import 'package:memora/presentation/notifiers/edit_state_notifier.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_confirm_dialog.dart';
import 'package:memora/presentation/shared/sheets/pin_detail_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

enum TripEditExpandedSection { map, routeInfo, tasks }

class TripEditModal extends HookConsumerWidget {
  const TripEditModal({
    super.key,
    required this.groupId,
    required this.groupMembers,
    this.tripEntry,
    required this.onSave,
    this.isTestEnvironment = false,
    this.year,
    this.nearbyLocationService,
  });

  final String groupId;
  final List<GroupMemberDto> groupMembers;
  final TripEntryDto? tripEntry;
  final Future<void> Function(TripEntryDto) onSave;
  final bool isTestEnvironment;
  final int? year;
  final NearbyLocationService? nearbyLocationService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = useState<String?>(null);
    final expandedSection = useState<TripEditExpandedSection?>(null);
    final selectedPin = useState<PinDto?>(null);
    final isBottomSheetVisible = useState(false);
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
        pins: List<PinDto>.from(tripEntry?.pins ?? const []),
        tasks: List<TaskDto>.from(tripEntry?.tasks ?? const []),
      );
    }, [groupId, tripEntry, year]);

    final draftTripEntry = useState(initialTripForComparison);

    List<PinDto> currentPins() =>
        List<PinDto>.from(draftTripEntry.value.pins ?? const []);

    List<TaskDto> currentTasks() =>
        List<TaskDto>.from(draftTripEntry.value.tasks ?? const []);

    void updateDraftTripEntry(TripEntryDto tripEntry) {
      draftTripEntry.value = tripEntry;
      errorMessage.value = null;
    }

    void updateDraftPins(List<PinDto> pins) {
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(pins: List<PinDto>.from(pins)),
      );
    }

    void updateDraftTasks(List<TaskDto> tasks) {
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(tasks: List<TaskDto>.from(tasks)),
      );
    }

    void updateDirtyState() {
      final isDirty = draftTripEntry.value != initialTripForComparison;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editStateNotifier.setDirty(isDirty);
      });
    }

    useEffect(() {
      updateDirtyState();
      return null;
    }, [draftTripEntry.value, initialTripForComparison]);

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
      final newPin = PinDto(
        pinId: const Uuid().v4(),
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        locationName: locationName,
      );
      updateDraftPins([...currentPins(), newPin]);
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

    void handlePinTapped(PinDto pin) {
      selectedPin.value = pin;
      isBottomSheetVisible.value = true;
    }

    void handlePinDeleted(String pinId) {
      updateDraftPins(
        currentPins().where((pin) => pin.pinId != pinId).toList(),
      );
      if (selectedPin.value?.pinId == pinId) {
        selectedPin.value = null;
      }
      hideBottomSheet();
    }

    void handlePinUpdated(PinDto pin) {
      final updatedPins = currentPins();
      final index = updatedPins.indexWhere(
        (current) => current.pinId == pin.pinId,
      );
      if (index == -1) {
        return;
      }
      updatedPins[index] = pin;
      updateDraftPins(updatedPins);
      hideBottomSheet();
    }

    void toggleMapExpansion() {
      if (expandedSection.value == TripEditExpandedSection.map) {
        expandedSection.value = null;
        hideBottomSheet();
        return;
      }
      expandedSection.value = TripEditExpandedSection.map;
    }

    void showRouteInfoView() {
      if (currentPins().length < 2) {
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
      final tripToSave = draftTripEntry.value;
      final selectedStart = tripToSave.tripStartDate;
      final selectedEnd = tripToSave.tripEndDate;
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

      try {
        final sortedTasks = currentTasks()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        await onSave(
          tripToSave.copyWith(
            tripStartDate: selectedStart,
            tripEndDate: selectedEnd,
            tasks: sortedTasks,
          ),
        );
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tripEntry != null ? '旅行編集' : '旅行新規作成',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          buildErrorBanner(),
          const SizedBox(height: 16),
          Expanded(
            child: TripEditFormView(
              value: draftTripEntry.value,
              configuredYear: tripEntry?.tripYear ?? year,
              onChanged: updateDraftTripEntry,
              onTaskManagementRequested: showTaskView,
              onVisitLocationEditRequested: toggleMapExpansion,
              onRouteInfoRequested: showRouteInfoView,
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
      );
    }

    Widget buildDialogContent() {
      switch (expandedSection.value) {
        case TripEditExpandedSection.map:
          return SelectVisitLocationView(
            pins: currentPins(),
            selectedPin: selectedPin.value,
            isTestEnvironment: isTestEnvironment,
            onClose: toggleMapExpansion,
            onMapLongTapped: handleMapLongTapped,
            onSearchedLocationSelected: handleSearchedLocationSelected,
            onPinTapped: handlePinTapped,
            onPinUpdated: handlePinUpdated,
            onPinDeleted: handlePinDeleted,
            bottomSheet: buildBottomSheet(),
          );
        case TripEditExpandedSection.routeInfo:
          return RouteInfoView(
            pins: currentPins(),
            isTestEnvironment: isTestEnvironment,
            onClose: closeRouteInfoView,
          );
        case TripEditExpandedSection.tasks:
          return TaskView(
            tripId: tripEntry?.id,
            tasks: currentTasks(),
            groupMembers: groupMembers,
            onChanged: updateDraftTasks,
            onClose: () => expandedSection.value = null,
          );
        case null:
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Material(
          type: MaterialType.card,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: buildDialogContent(),
          ),
        ),
      ),
    );
  }
}
