import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/application/queries/trip/itinerary_item_query_service.dart';

class WidgetItineraryDayQueryFixture implements AndroidWidgetItineraryQueryService {
  WidgetItineraryDayQueryFixture(this.trips, this.items);
  final TripEntryQueryService trips;
  final ItineraryItemQueryService items;
  final requestedDays = <DateTime>[];
  @override
  Future<DateTime?> findDate(String groupId, DateTime boundary, {required bool before}) async {
    final dates = <DateTime>{};
    for (final trip in await trips.getTripEntriesByGroupId(groupId)) {
      for (final item in await items.getItineraryItemsByTripId(trip.id)) {
        final start = item.startDateTime;
        if (start == null) continue;
        if (before ? start.isBefore(boundary) : !start.isBefore(boundary)) dates.add(DateTime(start.year, start.month, start.day));
      }
    }
    final sorted = dates.toList()..sort();
    return before ? sorted.lastOrNull : sorted.firstOrNull;
  }
  @override
  Future<List<TripEntryDto>> getDay(String groupId, DateTime day) async {
    requestedDays.add(day);
    final result = <TripEntryDto>[];
    for (final trip in await trips.getTripEntriesByGroupId(groupId)) {
      final onDay = (await items.getItineraryItemsByTripId(trip.id)).where((item) {
        final start = item.startDateTime;
        return start != null && start.year == day.year && start.month == day.month && start.day == day.day;
      }).toList();
      if (onDay.isNotEmpty) result.add(trip.copyWith(itineraryItems: onDay));
    }
    return result;
  }
}
