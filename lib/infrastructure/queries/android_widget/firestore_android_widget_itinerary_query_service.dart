import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/android_widget/android_widget_itinerary_query_service.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

class FirestoreAndroidWidgetItineraryQueryService
    implements AndroidWidgetItineraryQueryService {
  const FirestoreAndroidWidgetItineraryQueryService(this.firestore);
  final FirebaseFirestore firestore;
  Query<Map<String, dynamic>> _items(String groupId, String tripId) => firestore
      .collection('itinerary_items')
      .where('groupId', isEqualTo: groupId)
      .where('tripId', isEqualTo: tripId)
      .where('startDateTime', isNull: false);
  @override
  Future<DateTime?> findDate(
    String groupId,
    DateTime boundary, {
    required bool before,
  }) async {
    DateTime? found;
    for (final parent in await _parents(groupId)) {
      final base = _items(groupId, parent.id);
      final query = before
          ? base.where('startDateTime', isLessThan: Timestamp.fromDate(boundary))
          : base.where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(boundary));
      final rows = await query.orderBy('startDateTime', descending: before).limit(1).get();
      if (rows.docs.isEmpty) continue;
      final date = (rows.docs.single.data()['startDateTime'] as Timestamp).toDate();
      if (found == null || (before ? date.isAfter(found) : date.isBefore(found))) found = date;
    }
    return found == null ? null : DateTime(found.year, found.month, found.day);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _parents(String groupId) async =>
      (await firestore.collection('trip_entries').where('groupId', isEqualTo: groupId).get()).docs;

  @override
  Future<List<TripEntryDto>> getDay(String groupId, DateTime day) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day + 1);
    final trips = <TripEntryDto>[];
    for (final parent in await _parents(groupId)) {
      final rows = await _items(groupId, parent.id)
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
          .where('startDateTime', isLessThan: Timestamp.fromDate(to))
          .orderBy('startDateTime').get();
      if (rows.docs.isEmpty) continue;
      trips.add(FirestoreTripEntryMapper.fromFirestore(parent,
        fallbackTripYear: day.year,
        itineraryItems: rows.docs.map(FirestoreItineraryItemMapper.fromFirestore).toList()));
    }
    return trips;
  }
}
