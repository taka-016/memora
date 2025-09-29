import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/firestore_trip_entry_mapper.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    final docRef = await _firestore
        .collection('trip_entries')
        .add(FirestoreTripEntryMapper.toFirestore(tripEntry));
    return docRef.id;
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    await _firestore
        .collection('trip_entries')
        .doc(tripEntry.id)
        .update(FirestoreTripEntryMapper.toFirestore(tripEntry));
  }

  @override
  Future<List<TripEntry>> getTripEntriesByGroupId(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection('trip_entries')
          .where('groupId', isEqualTo: groupId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreTripEntryMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryRepository.getTripEntriesByGroupId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deleteTripEntry(String tripId) async {
    await _firestore.collection('trip_entries').doc(tripId).delete();
  }

  @override
  Future<TripEntry?> getTripEntryById(String tripId) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (doc.exists) {
        return FirestoreTripEntryMapper.fromFirestore(doc);
      }
      return null;
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryRepository.getTripEntryById: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<List<TripEntry>> getTripEntriesByGroupIdAndYear(
    String groupId,
    int year, {
    List<OrderBy>? orderBy,
  }) async {
    try {
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year + 1, 1, 1);

      Query<Map<String, dynamic>> query = _firestore
          .collection('trip_entries')
          .where('groupId', isEqualTo: groupId)
          .where(
            'tripStartDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where('tripStartDate', isLessThan: Timestamp.fromDate(endOfYear));

      // ソート条件が指定されている場合のみ適用
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => FirestoreTripEntryMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripEntryRepository.getTripEntriesByGroupIdAndYear: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {
    final snapshot = await _firestore
        .collection('trip_entries')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
