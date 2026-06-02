import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/transactions/trip_location_write_transaction.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';

class FirestoreTripLocationWriteTransaction
    implements TripLocationWriteTransaction {
  FirestoreTripLocationWriteTransaction({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<T> run<T>(
    Future<T> Function(TripLocationWriteTransactionOperations operations)
    action,
  ) {
    return _firestore.runTransaction<T>((transaction) async {
      final operations = _FirestoreTripLocationWriteTransactionOperations(
        firestore: _firestore,
        transaction: transaction,
      );
      return action(operations);
    });
  }
}

class _FirestoreTripLocationWriteTransactionOperations
    implements TripLocationWriteTransactionOperations {
  _FirestoreTripLocationWriteTransactionOperations({
    required FirebaseFirestore firestore,
    required Transaction transaction,
  }) : _firestore = firestore,
       _transaction = transaction;

  final FirebaseFirestore _firestore;
  final Transaction _transaction;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    final tripDocRef = _firestore.collection('trip_entries').doc();
    final tripId = tripDocRef.id;

    _transaction.set(
      tripDocRef,
      FirestoreTripEntryMapper.toCreateFirestore(tripEntry),
    );
    _createTasks(tripEntry.tasks, tripId: tripId);
    _createItineraryItems(tripEntry.itineraryItems, tripId: tripId);
    return tripId;
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    final tasksCollection = _firestore.collection('tasks');
    final itineraryItemsCollection = _firestore.collection('itinerary_items');
    final tasksSnapshot = await tasksCollection
        .where('tripId', isEqualTo: tripEntry.id)
        .get();
    final itineraryItemsSnapshot = await itineraryItemsCollection
        .where('tripId', isEqualTo: tripEntry.id)
        .get();

    _transaction.update(
      _firestore.collection('trip_entries').doc(tripEntry.id),
      FirestoreTripEntryMapper.toUpdateFirestore(tripEntry),
    );

    for (final taskDoc in tasksSnapshot.docs) {
      _transaction.delete(taskDoc.reference);
    }
    for (final itemDoc in itineraryItemsSnapshot.docs) {
      _transaction.delete(itemDoc.reference);
    }

    _createTasks(tripEntry.tasks, tripId: tripEntry.id);
    _createItineraryItems(tripEntry.itineraryItems, tripId: tripEntry.id);
  }

  @override
  Future<void> createLocation(Location location) async {
    final locationsCollection = _firestore.collection('locations');
    final locationDocRef = location.id.isEmpty
        ? locationsCollection.doc()
        : locationsCollection.doc(location.id);
    final locationToCreate = location.id.isEmpty
        ? location.copyWith(id: locationDocRef.id)
        : location;
    _transaction.set(
      locationDocRef,
      FirestoreLocationMapper.toCreateFirestore(locationToCreate),
    );
  }

  @override
  Future<void> updateLocation(Location location) async {
    _transaction.set(
      _firestore.collection('locations').doc(location.id),
      FirestoreLocationMapper.toUpdateFirestore(location),
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    _transaction.delete(_firestore.collection('locations').doc(locationId));
  }

  void _createTasks(List<Task> tasks, {required String tripId}) {
    final tasksCollection = _firestore.collection('tasks');
    for (final task in tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      _transaction.set(
        taskDocRef,
        FirestoreTaskMapper.toCreateFirestore(task.copyWith(tripId: tripId)),
      );
    }
  }

  void _createItineraryItems(
    List<ItineraryItem> itineraryItems, {
    required String tripId,
  }) {
    final itineraryItemsCollection = _firestore.collection('itinerary_items');
    for (final item in itineraryItems) {
      final itemDocRef = itineraryItemsCollection.doc(item.id);
      _transaction.set(
        itemDocRef,
        FirestoreItineraryItemMapper.toCreateFirestore(
          item.copyWith(tripId: tripId),
        ),
      );
    }
  }
}
