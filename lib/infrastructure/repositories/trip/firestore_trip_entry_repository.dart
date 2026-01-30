import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_pin_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripEntryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    final batch = _firestore.batch();

    final tripDocRef = _firestore.collection('trip_entries').doc();
    batch.set(tripDocRef, FirestoreTripEntryMapper.toFirestore(tripEntry));
    final tasksCollection = _firestore.collection('tasks');

    for (final Pin pin in tripEntry.pins) {
      final pinDocRef = _firestore.collection('pins').doc();
      batch.set(
        pinDocRef,
        FirestorePinMapper.toFirestore(pin.copyWith(tripId: tripDocRef.id)),
      );
    }

    for (final Task task in tripEntry.tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      batch.set(
        taskDocRef,
        FirestoreTaskMapper.toFirestore(task.copyWith(tripId: tripDocRef.id)),
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
      batch.delete(pinDoc.reference);
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
    }

    for (final Task task in tripEntry.tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      batch.set(
        taskDocRef,
        FirestoreTaskMapper.toFirestore(task.copyWith(tripId: tripEntry.id)),
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
      batch.delete(doc.reference);
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
        batch.delete(pinDoc.reference);
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
