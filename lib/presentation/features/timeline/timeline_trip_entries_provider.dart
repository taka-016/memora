import 'package:memora/composition_root/providers/usecases/trip/get_trip_entries_usecase.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/presentation/features/timeline/timeline_rows_refresh_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_trip_entries_provider.g.dart';

Duration? _disableRetry(int retryCount, Object error) => null;

@Riverpod(retry: _disableRetry)
Future<List<TripEntryDto>> timelineTripEntries(
  Ref ref, {
  required String groupId,
  required int year,
}) async {
  ref.watch(timelineRowsRefreshProvider);
  return await ref.watch(getTripEntriesUsecaseProvider).execute(groupId, year);
}
