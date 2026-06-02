import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';
import 'package:memora/infrastructure/repositories/firestore_write_context.dart';

class FirestoreLocationRepository implements LocationRepository {
  FirestoreLocationRepository({
    FirebaseFirestore? firestore,
    FirestoreWriteContext? writeContext,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _writeContext = writeContext;

  final FirebaseFirestore _firestore;
  final FirestoreWriteContext? _writeContext;

  @override
  Future<void> saveLocation(Location location) async {
    await _runWrite((context) async {
      final locationsCollection = context.collection('locations');
      if (location.id.isEmpty) {
        final locationDocRef = locationsCollection.doc();
        context.set(
          locationDocRef,
          FirestoreLocationMapper.toCreateFirestore(
            location.copyWith(id: locationDocRef.id),
          ),
        );
        return;
      }

      context.set(
        locationsCollection.doc(location.id),
        FirestoreLocationMapper.toCreateFirestore(location),
      );
    });
  }

  @override
  Future<void> updateLocation(Location location) async {
    await _runWrite((context) async {
      context.update(
        context.collection('locations').doc(location.id),
        FirestoreLocationMapper.toUpdateFirestore(location),
      );
    });
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    await _runWrite((context) async {
      final itineraryItemsSnapshot = await context.get(
        context
            .collection('itinerary_items')
            .where('locationId', isEqualTo: locationId),
      );

      for (final doc in itineraryItemsSnapshot.docs) {
        context.update(doc.reference, {'locationId': null});
      }

      context.delete(context.collection('locations').doc(locationId));
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
}
