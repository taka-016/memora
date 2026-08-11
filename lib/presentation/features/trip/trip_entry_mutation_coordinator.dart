import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/create_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/delete_trip_entry_usecase.dart';
import 'package:memora/application/usecases/trip/update_trip_entry_usecase.dart';
import 'package:memora/presentation/features/timeline/timeline_trip_entries_refresh_provider.dart';

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
        onTripEntriesChanged: () {
          ref.invalidate(timelineTripEntriesRefreshProvider);
        },
      );
    });

class TripEntryMutationCoordinator {
  TripEntryMutationCoordinator._({
    required this._createTripEntry,
    required this._updateTripEntry,
    required this._deleteTripEntry,
    required this._onTripEntriesChanged,
  });

  final Future<String> Function(TripEntryDto) _createTripEntry;
  final Future<void> Function(TripEntryDto) _updateTripEntry;
  final Future<void> Function(String) _deleteTripEntry;
  final void Function() _onTripEntriesChanged;

  Future<String> createTripEntry(TripEntryDto tripEntry) async {
    final id = await _createTripEntry(tripEntry);
    _onTripEntriesChanged();
    return id;
  }

  Future<void> updateTripEntry(TripEntryDto tripEntry) async {
    await _updateTripEntry(tripEntry);
    _onTripEntriesChanged();
  }

  Future<void> deleteTripEntry(String tripEntryId) async {
    await _deleteTripEntry(tripEntryId);
    _onTripEntriesChanged();
  }
}
