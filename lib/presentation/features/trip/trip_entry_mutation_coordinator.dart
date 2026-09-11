import 'package:memora/composition_root/providers/android_widget_providers.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/composition_root/providers/trip_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_provider.dart';

final tripEntryMutationCoordinatorProvider =
    Provider<TripEntryMutationCoordinator>((ref) {
      return TripEntryMutationCoordinator._(
        createTripEntry: (tripEntry) {
          return ref.read(createTripEntryUsecaseProvider).execute(tripEntry);
        },
        updateTripEntry: (tripEntry) {
          return ref.read(updateTripEntryUsecaseProvider).execute(tripEntry);
        },
        deleteTripEntry: (tripEntryId) {
          return ref.read(deleteTripEntryUsecaseProvider).execute(tripEntryId);
        },
        refreshWidget: () =>
            ref.read(refreshSelectedAndroidWidgetCacheProvider)(),
        onTripEntriesChanged: () {
          ref.invalidate(timelineTripEntriesProvider);
        },
      );
    });

class TripEntryMutationCoordinator {
  TripEntryMutationCoordinator._({
    required this._createTripEntry,
    required this._updateTripEntry,
    required this._deleteTripEntry,
    required this._onTripEntriesChanged,
    required this._refreshWidget,
  });

  final Future<String> Function(TripEntryDto) _createTripEntry;
  final Future<void> Function(TripEntryDto) _updateTripEntry;
  final Future<void> Function(String) _deleteTripEntry;
  final void Function() _onTripEntriesChanged;
  final Future<void> Function() _refreshWidget;

  Future<void> _refreshWidgetAfterMutation() async {
    try {
      await _refreshWidget();
    } catch (error, stackTrace) {
      logger.w('保存後のウィジェット更新に失敗しました', error: error, stackTrace: stackTrace);
    }
  }

  Future<String> createTripEntry(TripEntryDto tripEntry) async {
    final id = await _createTripEntry(tripEntry);
    _onTripEntriesChanged();
    await _refreshWidgetAfterMutation();
    return id;
  }

  Future<void> updateTripEntry(TripEntryDto tripEntry) async {
    await _updateTripEntry(tripEntry);
    _onTripEntriesChanged();
    await _refreshWidgetAfterMutation();
  }

  Future<void> deleteTripEntry(String tripEntryId) async {
    await _deleteTripEntry(tripEntryId);
    _onTripEntriesChanged();
    await _refreshWidgetAfterMutation();
  }
}
