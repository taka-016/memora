import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/trip_entry_repository.dart';
import 'package:memora/domain/entities/trip_entry.dart';
import 'package:memora/domain/entities/pin.dart';
import 'package:memora/domain/value_objects/order_by.dart';
import 'package:memora/core/app_logger.dart';
import 'package:memora/infrastructure/mappers/firestore_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_mapper.dart';
import 'package:memora/infrastructure/mappers/firestore_pin_detail_mapper.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    final batch = _firestore.batch();

    final tripDocRef = _firestore.collection('trip_entries').doc();
    batch.set(tripDocRef, FirestoreTripEntryMapper.toFirestore(tripEntry));

    for (final Pin pin in tripEntry.pins) {
      final pinDocRef = _firestore.collection('pins').doc();
      batch.set(
        pinDocRef,
        FirestorePinMapper.toFirestore(pin.copyWith(tripId: tripDocRef.id)),
      );

      for (final detail in pin.details) {
        final detailDocRef = _firestore.collection('pin_details').doc();
        batch.set(
          detailDocRef,
          FirestorePinDetailMapper.toFirestore(
            detail.copyWith(pinId: pin.pinId),
          ),
        );
      }
    }

    await batch.commit();
    return tripDocRef.id;
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('trip_entries').doc(tripEntry.id),
      FirestoreTripEntryMapper.toFirestore(tripEntry),
    );

    if (tripEntry.pins.isNotEmpty) {
      final pinsSnapshot = await _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripEntry.id)
          .get();
      for (final doc in pinsSnapshot.docs) {
        final pinId = doc.data()['pinId'] as String? ?? '';

        final detailsSnapshot = await _firestore
            .collection('pin_details')
            .where('pinId', isEqualTo: pinId)
            .get();
        for (final detailDoc in detailsSnapshot.docs) {
          batch.delete(detailDoc.reference);
        }

        batch.delete(doc.reference);
      }

      for (final Pin pin in tripEntry.pins) {
        final pinDocRef = _firestore.collection('pins').doc();
        batch.set(
          pinDocRef,
          FirestorePinMapper.toFirestore(pin.copyWith(tripId: tripEntry.id)),
        );

        for (final detail in pin.details) {
          final detailDocRef = _firestore.collection('pin_details').doc();
          batch.set(
            detailDocRef,
            FirestorePinDetailMapper.toFirestore(
              detail.copyWith(pinId: pin.pinId),
            ),
          );
        }
      }
    }

    await batch.commit();
  }

  @override
  Future<void> deleteTripEntry(String tripId) async {
    final batch = _firestore.batch();

    final pinsSnapshot = await _firestore
        .collection('pins')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in pinsSnapshot.docs) {
      final pinId = doc.data()['pinId'] as String? ?? '';

      final detailsSnapshot = await _firestore
          .collection('pin_details')
          .where('pinId', isEqualTo: pinId)
          .get();
      for (final detailDoc in detailsSnapshot.docs) {
        batch.delete(detailDoc.reference);
      }

      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('trip_entries').doc(tripId));
    await batch.commit();
  }

  @override
  Future<TripEntry?> getTripEntryById(String tripId) async {
    try {
      final doc = await _firestore.collection('trip_entries').doc(tripId).get();
      if (!doc.exists) {
        return null;
      }

      final pinsSnapshot = await _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId)
          .get();

      final pins = <Pin>[];
      for (final pinDoc in pinsSnapshot.docs) {
        final pinId = pinDoc.data()['pinId'] as String? ?? '';

        final pinDetailsSnapshot = await _firestore
            .collection('pin_details')
            .where('pinId', isEqualTo: pinId)
            .get();

        final pinDetails = pinDetailsSnapshot.docs
            .map(
              (detailDoc) => FirestorePinDetailMapper.fromFirestore(detailDoc),
            )
            .toList();

        final pin = FirestorePinMapper.fromFirestore(
          pinDoc,
          details: pinDetails,
        );
        pins.add(pin);
      }

      return FirestoreTripEntryMapper.fromFirestore(doc, pins: pins);
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
