import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/task_mapper.dart';
import 'package:memora/application/mappers/trip/trip_entry_mapper.dart';
import 'package:memora/application/queries/trip/trip_entry_query_service.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/domain/value_objects/order_by.dart';

class FirestoreTripEntryQueryService implements TripEntryQueryService {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryQueryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<TripEntryDto?> getTripEntryById(
    String tripId, {
    List<OrderBy>? pinsOrderBy,
    List<OrderBy>? tasksOrderBy,
  }) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      Query<Map<String, dynamic>> pinsQuery = _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId);

      if (pinsOrderBy != null && pinsOrderBy.isNotEmpty) {
        for (final order in pinsOrderBy) {
          pinsQuery = pinsQuery.orderBy(
            order.field,
            descending: order.descending,
          );
        }
      }

      final pinsSnapshot = await pinsQuery.get();
      final pins = pinsSnapshot.docs
          .map((pinDoc) => PinMapper.fromFirestore(pinDoc))
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
          .map((taskDoc) => TaskMapper.fromFirestore(taskDoc))
          .toList();

      return TripEntryMapper.fromFirestore(doc, pins: pins, tasks: tasks);
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
          .where('tripYear', isEqualTo: year);

      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => TripEntryMapper.fromFirestore(doc))
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
