import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/dtos/group/group_member_dto.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/exceptions/application_validation_exception.dart';
import 'package:memora/application/usecases/location/get_nearby_location_name_usecase.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/presentation/features/trip/itinerary_view.dart';
import 'package:memora/presentation/features/trip/task_view.dart';
import 'package:memora/presentation/features/trip/trip_edit_form_view.dart';
import 'package:memora/presentation/notifiers/edit_state_notifier.dart';
import 'package:memora/presentation/shared/dialogs/edit_discard_confirm_dialog.dart';

enum TripEditExpandedSection { itinerary, tasks }

typedef TripEditSave = Future<void> Function(TripEntryDto tripEntry);

class TripEditModal extends HookConsumerWidget {
  const TripEditModal({
    super.key,
    required this.groupId,
    required this.groupMembers,
    this.tripEntry,
    required this.onSave,
    this.isTestEnvironment = false,
    this.year,
  });

  final String groupId;
  final List<GroupMemberDto> groupMembers;
  final TripEntryDto? tripEntry;
  final TripEditSave onSave;
  final bool isTestEnvironment;
  final int? year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = useState<String?>(null);
    final expandedSection = useState<TripEditExpandedSection?>(null);
    final editStateNotifier = ref.read(editStateNotifierProvider.notifier);
    final editState = ref.watch(editStateNotifierProvider);
    final clock = ref.watch(appClockProvider);

    final initialTripForComparison = useMemoized(() {
      final tripYearValue = tripEntry?.year ?? year ?? clock.now().year;
      return TripEntryDto(
        id: tripEntry?.id ?? '',
        groupId: groupId,
        year: tripYearValue,
        name: tripEntry?.name,
        startDate: tripEntry?.startDate,
        endDate: tripEntry?.endDate,
        memo: tripEntry?.memo ?? '',
        locations: List<LocationDto>.from(tripEntry?.locations ?? const []),
        tasks: List<TaskDto>.from(tripEntry?.tasks ?? const []),
        itineraryItems: List<ItineraryItemDto>.from(
          tripEntry?.itineraryItems ?? const [],
        ),
      );
    }, [groupId, tripEntry, year, clock]);

    final draftTripEntry = useState(initialTripForComparison);

    List<LocationDto> currentLocations() =>
        List<LocationDto>.from(draftTripEntry.value.locations ?? const []);

    List<TaskDto> currentTasks() =>
        List<TaskDto>.from(draftTripEntry.value.tasks ?? const []);

    List<ItineraryItemDto> currentItineraryItems() =>
        List<ItineraryItemDto>.from(
          draftTripEntry.value.itineraryItems ?? const [],
        );

    void updateDraftTripEntry(TripEntryDto tripEntry) {
      draftTripEntry.value = tripEntry;
      errorMessage.value = null;
    }

    void updateDraftItineraryItems(List<ItineraryItemDto> itineraryItems) {
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(
          itineraryItems: List<ItineraryItemDto>.from(itineraryItems),
        ),
      );
    }

    void updateDraftTasks(List<TaskDto> tasks) {
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(tasks: List<TaskDto>.from(tasks)),
      );
    }

    Future<LocationDto> saveTripLocation(LocationDto location) async {
      final getNearbyLocationNameUsecase = ref.read(
        getNearbyLocationNameUsecaseProvider,
      );
      final locationName =
          location.name ??
          await getNearbyLocationNameUsecase.execute(location.coordinate);
      final locationToSave = location.copyWith(name: locationName);
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(
          locations: [
            ...currentLocations().where((current) => current.id != location.id),
            locationToSave,
          ],
        ),
      );
      return locationToSave;
    }

    Future<void> deleteTripLocation(LocationDto location) async {
      updateDraftTripEntry(
        draftTripEntry.value.copyWith(
          locations: currentLocations()
              .where((current) => current.id != location.id)
              .toList(),
          itineraryItems: currentItineraryItems()
              .map(
                (item) => item.locationId == location.id
                    ? item.copyWith(locationId: null, location: null)
                    : item,
              )
              .toList(),
        ),
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

    void showTaskView() {
      expandedSection.value = TripEditExpandedSection.tasks;
    }

    void showItineraryView() {
      expandedSection.value = TripEditExpandedSection.itinerary;
    }

    Future<void> handleSave() async {
      errorMessage.value = null;
      final tripToSave = draftTripEntry.value;
      final selectedStart = tripToSave.startDate;
      final selectedEnd = tripToSave.endDate;
      final tripYearValue = tripEntry?.year ?? year ?? clock.now().year;

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
        final sortedItineraryItems = sortItineraryItems(
          currentItineraryItems(),
        );
        await onSave(
          tripToSave.copyWith(
            startDate: selectedStart,
            endDate: selectedEnd,
            locations: currentLocations(),
            tasks: sortedTasks,
            itineraryItems: sortedItineraryItems,
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
              locations: currentLocations(),
              isTestEnvironment: isTestEnvironment,
              configuredYear: tripEntry?.year ?? year,
              clock: clock,
              onChanged: updateDraftTripEntry,
              onItineraryManagementRequested: showItineraryView,
              onTaskManagementRequested: showTaskView,
              onLocationCreated: saveTripLocation,
              onLocationDeleted: deleteTripLocation,
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
        case TripEditExpandedSection.tasks:
          return TaskView(
            tripId: tripEntry?.id,
            tasks: currentTasks(),
            groupMembers: groupMembers,
            tripStartDate: draftTripEntry.value.startDate,
            onChanged: updateDraftTasks,
            onClose: () => expandedSection.value = null,
          );
        case TripEditExpandedSection.itinerary:
          return ItineraryView(
            tripId: tripEntry?.id,
            groupId: groupId,
            tripStartDate: draftTripEntry.value.startDate,
            items: currentItineraryItems(),
            locations: currentLocations(),
            onLocationCreated: saveTripLocation,
            onLocationDeleted: deleteTripLocation,
            isTestEnvironment: isTestEnvironment,
            onChanged: updateDraftItineraryItems,
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
