import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

class FirestoreTripEntryQueryService implements TripEntryQueryService {
  final FirebaseFirestore _firestore;
  final AppClock _clock;

  FirestoreTripEntryQueryService({
    FirebaseFirestore? firestore,
    AppClock? clock,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _clock = clock ?? NtpSynchronizedAppClock();

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      Query<Map<String, dynamic>> pinsQuery = _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId);

      final pinsSnapshot = await pinsQuery.get();
      final pins = _sortDocuments(
        pinsSnapshot.docs,
        pinsOrderBy,
      ).map((pinDoc) => FirestorePinMapper.fromFirestore(pinDoc)).toList();

      Query<Map<String, dynamic>> tasksQuery = _firestore
          .collection('tasks')
          .where('tripId', isEqualTo: tripId);

      final tasksSnapshot = await tasksQuery.get();
      final tasks = _sortDocuments(
        tasksSnapshot.docs,
        tasksOrderBy,
      ).map((taskDoc) => FirestoreTaskMapper.fromFirestore(taskDoc)).toList();

      Query<Map<String, dynamic>> itineraryItemsQuery = _firestore
          .collection('itinerary_items')
          .where('tripId', isEqualTo: tripId);

      final effectiveItineraryItemsOrderBy =
          itineraryItemsOrderBy ??
          const [OrderBy('orderIndex', descending: false)];
      final itineraryItemsSnapshot = await itineraryItemsQuery.get();
      final itineraryItems =
          _sortDocuments(
                itineraryItemsSnapshot.docs,
                effectiveItineraryItemsOrderBy,
              )
              .map(
                (itineraryItemDoc) =>
                    FirestoreItineraryItemMapper.fromFirestore(
                      itineraryItemDoc,
                    ),
              )
              .toList();

      return FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: _clock.now().year,
        pins: pins,
        tasks: tasks,
        itineraryItems: itineraryItems,
      );
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryQueryService.getTripEntryById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<TripEntryDto>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('trip_entries')
          .where('groupId', isEqualTo: groupId)
          .where('year', isEqualTo: year);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => FirestoreTripEntryMapper.fromFirestore(
              doc,
              fallbackTripYear: _clock.now().year,
            ),
          )
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryQueryService.getTripEntriesByGroupIdAndYear: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<OrderBy>? orderBy,
  ) {
    if (orderBy == null || orderBy.isEmpty) {
      return docs;
    }

    return List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs)
      ..sort((a, b) {
        for (final order in orderBy) {
          final comparison = _compareFieldValues(
            a.data()[order.field],
            b.data()[order.field],
          );
          if (comparison != 0) {
            return order.descending ? -comparison : comparison;
          }
        }
        return 0;
      });
  }

  int _compareFieldValues(Object? a, Object? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }

    final normalizedA = _normalizeComparableValue(a);
    final normalizedB = _normalizeComparableValue(b);

    if (normalizedA is num && normalizedB is num) {
      return normalizedA.compareTo(normalizedB);
    }
    if (normalizedA is DateTime && normalizedB is DateTime) {
      return normalizedA.compareTo(normalizedB);
    }
    if (normalizedA is String && normalizedB is String) {
      return normalizedA.compareTo(normalizedB);
    }
    if (normalizedA is bool && normalizedB is bool) {
      return normalizedA == normalizedB ? 0 : (normalizedA ? 1 : -1);
    }

    return normalizedA.toString().compareTo(normalizedB.toString());
  }

  Object _normalizeComparableValue(Object value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return value;
  }
}
