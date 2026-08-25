import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';

final timelineTripEntriesProvider = FutureProvider.autoDispose
    .family<List<TripEntryDto>, TimelineTripEntriesQuery>((ref, query) async {
      ref.watch(timelineRowsRefreshProvider);
      return await ref
          .watch(getTripEntriesUsecaseProvider)
          .execute(query.groupId, query.year);
    }, retry: (_, _) => null);

class TimelineTripEntriesQuery {
  const TimelineTripEntriesQuery({required this.groupId, required this.year});

  final String groupId;
  final int year;

  @override
  bool operator ==(Object other) {
    return other is TimelineTripEntriesQuery &&
        other.groupId == groupId &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(groupId, year);
}
