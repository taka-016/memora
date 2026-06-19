import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/core/time/app_clock.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

class FirestoreTripEntryQueryService implements TripEntryQueryService {
  final FirebaseFirestore _firestore;
  final AppClock _clock;

  FirestoreTripEntryQueryService({
    FirebaseFirestore? firestore,
    AppClock? clock,
    bool rethrowOnError = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _clock = clock ?? NtpSynchronizedAppClock(),
       _rethrowOnError = rethrowOnError;

  final bool _rethrowOnError;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? tasksOrderBy,
    List<OrderBy>? itineraryItemsOrderBy,
  }) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      final locationsSnapshot = await _firestore
          .collection('locations')
          .where('tripId', isEqualTo: tripId)
          .get();
      final locations = locationsSnapshot.docs
          .map(FirestoreLocationMapper.fromFirestore)
          .toList();

      Query<Map<String, dynamic>> tasksQuery = _firestore
          .collection('tasks')
          .where('tripId', isEqualTo: tripId);

      if (tasksOrderBy != null && tasksOrderBy.isNotEmpty) {
        for (final order in tasksOrderBy) {
          tasksQuery = tasksQuery.orderBy(
            order.field,
            descending: order.descending,
          );
        }
      }

      final tasksSnapshot = await tasksQuery.get();
      final tasks = tasksSnapshot.docs
          .map((taskDoc) => FirestoreTaskMapper.fromFirestore(taskDoc))
          .toList();

      Query<Map<String, dynamic>> itineraryItemsQuery = _firestore
          .collection('itinerary_items')
          .where('tripId', isEqualTo: tripId);

      final effectiveItineraryItemsOrderBy =
          itineraryItemsOrderBy ??
          const [
            OrderBy('startDateTime', descending: false),
            OrderBy('endDateTime', descending: false),
          ];
      for (final order in effectiveItineraryItemsOrderBy) {
        itineraryItemsQuery = itineraryItemsQuery.orderBy(
          order.field,
          descending: order.descending,
        );
      }

      final itineraryItemsSnapshot = await itineraryItemsQuery.get();
      final itineraryItems = itineraryItemsSnapshot.docs
          .map(
            (itineraryItemDoc) =>
                FirestoreItineraryItemMapper.fromFirestore(itineraryItemDoc),
          )
          .toList();

      return FirestoreTripEntryMapper.fromFirestore(
        doc,
        fallbackTripYear: _clock.now().year,
        locations: locations,
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
  Future<List<TripEntryDto>> getTripEntriesByGroupId(
    String groupId, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('trip_entries')
          .where('groupId', isEqualTo: groupId);

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
        'FirestoreTripEntryQueryService.getTripEntriesByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      if (_rethrowOnError) {
        rethrow;
      }
      return [];
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
}
