import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/route.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_detail_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_route_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    final batch = _firestore.batch();

    final tripDocRef = _firestore.collection('trip_entries').doc(tripEntry.id);
    batch.set(tripDocRef, FirestoreTripEntryMapper.toFirestore(tripEntry));
    final tasksCollection = _firestore.collection('tasks');

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

    for (final Route route in tripEntry.routes) {
      final routeDocRef = _firestore.collection('routes').doc();
      batch.set(
        routeDocRef,
        FirestoreRouteMapper.toFirestore(route.copyWith(tripId: tripDocRef.id)),
      );
    }

    for (final Task task in tripEntry.tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      batch.set(
        taskDocRef,
        FirestoreTaskMapper.toFirestore(task),
      );
    }

    await batch.commit();
    return tripDocRef.id;
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    final batch = _firestore.batch();
    final tasksCollection = _firestore.collection('tasks');

    batch.update(
      _firestore.collection('trip_entries').doc(tripEntry.id),
      FirestoreTripEntryMapper.toFirestore(tripEntry),
    );

    final pinsSnapshot = await _firestore
        .collection('pins')
        .where('tripId', isEqualTo: tripEntry.id)
        .get();
    for (final pinDoc in pinsSnapshot.docs) {
      final pinId = pinDoc.data()['pinId'] as String? ?? '';

      final detailsSnapshot = await _firestore
          .collection('pin_details')
          .where('pinId', isEqualTo: pinId)
          .get();
      for (final detailDoc in detailsSnapshot.docs) {
        batch.delete(detailDoc.reference);
      }

      batch.delete(pinDoc.reference);
    }

    final routesSnapshot = await _firestore
        .collection('routes')
        .where('tripId', isEqualTo: tripEntry.id)
        .get();
    for (final routeDoc in routesSnapshot.docs) {
      batch.delete(routeDoc.reference);
    }

    final tasksSnapshot = await tasksCollection
        .where('tripId', isEqualTo: tripEntry.id)
        .get();
    for (final taskDoc in tasksSnapshot.docs) {
      batch.delete(taskDoc.reference);
    }

    for (final Pin pin in tripEntry.pins) {
      final pinDocRef = _firestore.collection('pins').doc();
      batch.set(
        pinDocRef,
        FirestorePinMapper.toFirestore(
          pin.copyWith(tripId: tripEntry.id, groupId: tripEntry.groupId),
        ),
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

    for (final Route route in tripEntry.routes) {
      final routeDocRef = _firestore.collection('routes').doc();
      batch.set(
        routeDocRef,
        FirestoreRouteMapper.toFirestore(route.copyWith(tripId: tripEntry.id)),
      );
    }

    for (final Task task in tripEntry.tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      batch.set(
        taskDocRef,
        FirestoreTaskMapper.toFirestore(task),
      );
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

    final routesSnapshot = await _firestore
        .collection('routes')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final routeDoc in routesSnapshot.docs) {
      batch.delete(routeDoc.reference);
    }

    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final taskDoc in tasksSnapshot.docs) {
      batch.delete(taskDoc.reference);
    }

    batch.delete(_firestore.collection('trip_entries').doc(tripId));
    await batch.commit();
  }

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {
    final batch = _firestore.batch();

    final tripEntriesSnapshot = await _firestore
        .collection('trip_entries')
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final tripEntryDoc in tripEntriesSnapshot.docs) {
      final pinsSnapshot = await _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripEntryDoc.id)
          .get();
      for (final pinDoc in pinsSnapshot.docs) {
        final pinId = pinDoc.data()['pinId'] as String? ?? '';

        final detailsSnapshot = await _firestore
            .collection('pin_details')
            .where('pinId', isEqualTo: pinId)
            .get();
        for (final detailDoc in detailsSnapshot.docs) {
          batch.delete(detailDoc.reference);
        }
        batch.delete(pinDoc.reference);
      }
      final routesSnapshot = await _firestore
          .collection('routes')
          .where('tripId', isEqualTo: tripEntryDoc.id)
          .get();
      for (final routeDoc in routesSnapshot.docs) {
        batch.delete(routeDoc.reference);
      }
      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('tripId', isEqualTo: tripEntryDoc.id)
          .get();
      for (final taskDoc in tasksSnapshot.docs) {
        batch.delete(taskDoc.reference);
      }
      batch.delete(tripEntryDoc.reference);
    }
    await batch.commit();
  }
}
