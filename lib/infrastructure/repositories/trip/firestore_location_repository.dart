import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/location.dart';
import 'package:memora/domain/repositories/trip/location_repository.dart';
import 'package:memora/infrastructure/mappers/trip/firestore_location_mapper.dart';

class FirestoreLocationRepository implements LocationRepository {
  FirestoreLocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveLocation(Location location) async {
    final collection = _firestore.collection('locations');
    if (location.id.isEmpty) {
      await collection.add(FirestoreLocationMapper.toCreateFirestore(location));
      return;
    }

    await collection
        .doc(location.id)
        .set(FirestoreLocationMapper.toUpdateFirestore(location));
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    final batch = _firestore.batch();
    final itineraryItemsSnapshot = await _firestore
        .collection('itinerary_items')
        .where('locationId', isEqualTo: locationId)
        .get();

    for (final doc in itineraryItemsSnapshot.docs) {
      batch.update(doc.reference, {'locationId': null});
    }

    batch.delete(_firestore.collection('locations').doc(locationId));
    await batch.commit();
  }
}
