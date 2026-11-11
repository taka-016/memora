import 'package:memora/application/dtos/trip/trip_entry_dto.dart';

abstract class AndroidWidgetItineraryQueryService {
  Future<List<TripEntryDto>> getDay(String groupId, DateTime day);
  Future<DateTime?> findDate(
    String groupId,
    DateTime boundary, {
    required bool before,
  });
}
