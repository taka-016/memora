import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

class FirestoreAndroidWidgetItineraryQueryService implements AndroidWidgetItineraryQueryService {
  const FirestoreAndroidWidgetItineraryQueryService(this.firestore);
  final FirebaseFirestore firestore;
  Query<Map<String, dynamic>> _items(String groupId) => firestore.collection('itinerary_items').where('groupId', isEqualTo: groupId).where('startDateTime', isNull: false);
  @override
  Future<DateTime?> findDate(String groupId, DateTime boundary, {required bool before}) async {
    final query = before
        ? _items(groupId).where('startDateTime', isLessThan: Timestamp.fromDate(boundary))
        : _items(groupId).where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(boundary));
    final rows = await query.orderBy('startDateTime', descending: before).limit(1).get();
    if (rows.docs.isEmpty) return null;
    final date = (rows.docs.single.data()['startDateTime'] as Timestamp).toDate();
    return DateTime(date.year, date.month, date.day);
  }
  @override
  Future<List<TripEntryDto>> getDay(String groupId, DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final rows = await _items(groupId).where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('startDateTime', isLessThan: Timestamp.fromDate(to)).orderBy('startDateTime').get();
    final grouped = <String, List<ItineraryItemDto>>{};
    for (final row in rows.docs) {
      final item = FirestoreItineraryItemMapper.fromFirestore(row);
      grouped.putIfAbsent(item.tripId, () => []).add(item);
    }
    final trips = <TripEntryDto>[];
    for (final entry in grouped.entries) {
      final parent = await firestore.collection('trip_entries').doc(entry.key).get();
      if (!parent.exists) throw StateError('旅行が変更されています。再取得してください');
      trips.add(FirestoreTripEntryMapper.fromFirestore(parent, fallbackTripYear: day.year, itineraryItems: entry.value));
    }
    return trips;
  }
}
