import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/repositories/trip/trip_entry_repository.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/entities/trip/task.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_itinerary_item_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_trip_entry_mapper.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_task_mapper.dart';
import 'package:memora/infrastructure/repositories/firestore_write_context.dart';

class FirestoreTripEntryRepository implements TripEntryRepository {
  final FirebaseFirestore _firestore;
  final FirestoreWriteContext? _writeContext;

  FirestoreTripEntryRepository({
    FirebaseFirestore? firestore,
    FirestoreWriteContext? writeContext,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _writeContext = writeContext;

  @override
  Future<String> saveTripEntry(TripEntry tripEntry) async {
    return _runWrite((context) async {
      final tripDocRef = context.collection('trip_entries').doc();
      context.set(
        tripDocRef,
        FirestoreTripEntryMapper.toCreateFirestore(tripEntry),
      );
      _createLocations(context, tripEntry.locations, tripId: tripDocRef.id);
      _createTasks(context, tripEntry.tasks, tripId: tripDocRef.id);
      _createItineraryItems(
        context,
        tripEntry.itineraryItems,
        tripId: tripDocRef.id,
      );
      return tripDocRef.id;
    });
  }

  @override
  Future<void> updateTripEntry(TripEntry tripEntry) async {
    await _runWrite((context) async {
      final locationsCollection = context.collection('locations');
      final tasksCollection = context.collection('tasks');
      final itineraryItemsCollection = context.collection('itinerary_items');

      final locationsSnapshot = await context.get(
        locationsCollection.where('tripId', isEqualTo: tripEntry.id),
      );
      final tasksSnapshot = await context.get(
        tasksCollection.where('tripId', isEqualTo: tripEntry.id),
      );
      final itineraryItemsSnapshot = await context.get(
        itineraryItemsCollection.where('tripId', isEqualTo: tripEntry.id),
      );

      context.update(
        context.collection('trip_entries').doc(tripEntry.id),
        FirestoreTripEntryMapper.toUpdateFirestore(tripEntry),
      );

      for (final locationDoc in locationsSnapshot.docs) {
        context.delete(locationDoc.reference);
      }
      for (final taskDoc in tasksSnapshot.docs) {
        context.delete(taskDoc.reference);
      }
      for (final itemDoc in itineraryItemsSnapshot.docs) {
        context.delete(itemDoc.reference);
      }

      _createLocations(context, tripEntry.locations, tripId: tripEntry.id);
      _createTasks(context, tripEntry.tasks, tripId: tripEntry.id);
      _createItineraryItems(
        context,
        tripEntry.itineraryItems,
        tripId: tripEntry.id,
      );
    });
  }

  @override
  Future<void> deleteTripEntry(String tripId) async {
    await _runWrite((context) async {
      final locationsSnapshot = await context.get(
        context.collection('locations').where('tripId', isEqualTo: tripId),
      );
      for (final locationDoc in locationsSnapshot.docs) {
        context.delete(locationDoc.reference);
      }

      final tasksSnapshot = await context.get(
        context.collection('tasks').where('tripId', isEqualTo: tripId),
      );
      for (final taskDoc in tasksSnapshot.docs) {
        context.delete(taskDoc.reference);
      }

      final itineraryItemsSnapshot = await context.get(
        context
            .collection('itinerary_items')
            .where('tripId', isEqualTo: tripId),
      );
      for (final itemDoc in itineraryItemsSnapshot.docs) {
        context.delete(itemDoc.reference);
      }

      context.delete(context.collection('trip_entries').doc(tripId));
    });
  }

  @override
  Future<void> deleteTripEntriesByGroupId(String groupId) async {
    await _runWrite((context) async {
      final tripEntriesSnapshot = await context.get(
        context.collection('trip_entries').where('groupId', isEqualTo: groupId),
      );
      for (final tripEntryDoc in tripEntriesSnapshot.docs) {
        final locationsSnapshot = await context.get(
          context
              .collection('locations')
              .where('tripId', isEqualTo: tripEntryDoc.id),
        );
        for (final locationDoc in locationsSnapshot.docs) {
          context.delete(locationDoc.reference);
        }
        final tasksSnapshot = await context.get(
          context
              .collection('tasks')
              .where('tripId', isEqualTo: tripEntryDoc.id),
        );
        for (final taskDoc in tasksSnapshot.docs) {
          context.delete(taskDoc.reference);
        }
        final itineraryItemsSnapshot = await context.get(
          context
              .collection('itinerary_items')
              .where('tripId', isEqualTo: tripEntryDoc.id),
        );
        for (final itemDoc in itineraryItemsSnapshot.docs) {
          context.delete(itemDoc.reference);
        }
        context.delete(tripEntryDoc.reference);
      }
    });
  }

  Future<T> _runWrite<T>(
    Future<T> Function(FirestoreWriteContext context) action,
  ) async {
    final sharedContext = _writeContext;
    if (sharedContext != null) {
      return action(sharedContext);
    }

    final context = FirestoreBatchWriteContext(firestore: _firestore);
    final result = await action(context);
    await context.commit();
    return result;
  }

  void _createLocations(
    FirestoreWriteContext context,
    List<Location> locations, {
    required String tripId,
  }) {
    if (locations.isEmpty) {
      return;
    }

    final locationsCollection = context.collection('locations');
    for (final location in locations) {
      final locationDocRef = locationsCollection.doc(location.id);
      context.set(
        locationDocRef,
        FirestoreLocationMapper.toCreateFirestore(
          location.copyWith(tripId: tripId),
        ),
      );
    }
  }

  void _createTasks(
    FirestoreWriteContext context,
    List<Task> tasks, {
    required String tripId,
  }) {
    if (tasks.isEmpty) {
      return;
    }

    final tasksCollection = context.collection('tasks');
    for (final task in tasks) {
      final taskDocRef = tasksCollection.doc(task.id);
      context.set(
        taskDocRef,
        FirestoreTaskMapper.toCreateFirestore(task.copyWith(tripId: tripId)),
      );
    }
  }

  void _createItineraryItems(
    FirestoreWriteContext context,
    List<ItineraryItem> itineraryItems, {
    required String tripId,
  }) {
    if (itineraryItems.isEmpty) {
      return;
    }

    final itineraryItemsCollection = context.collection('itinerary_items');
    for (final item in itineraryItems) {
      final itemDocRef = itineraryItemsCollection.doc(item.id);
      context.set(
        itemDocRef,
        FirestoreItineraryItemMapper.toCreateFirestore(
          item.copyWith(tripId: tripId),
        ),
      );
    }
  }
}
