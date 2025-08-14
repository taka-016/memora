import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/entities/pin.dart';
import '../mappers/firestore_pin_mapper.dart';

class FirestorePinRepository implements PinRepository {
  final FirebaseFirestore _firestore;

  FirestorePinRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> savePin(String pinId, double latitude, double longitude) async {
    await _firestore.collection('pins').add({
      'pinId': pinId,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Pin>> getPins() async {
    try {
      final snapshot = await _firestore.collection('pins').get();
      return snapshot.docs
          .map((doc) => FirestorePinMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deletePin(String pinId) async {
    final query = await _firestore
        .collection('pins')
        .where('pinId', isEqualTo: pinId)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }

  @override
  Future<List<Pin>> getPinsByTripId(String tripId) async {
    try {
      final snapshot = await _firestore
          .collection('pins')
          .where('tripId', isEqualTo: tripId)
          .get();
      return snapshot.docs
          .map((doc) => FirestorePinMapper.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> savePinWithTrip(Pin pin) async {
    await _firestore
        .collection('pins')
        .add(FirestorePinMapper.toFirestore(pin));
  }

  @override
  Future<void> deletePinsByTripId(String tripId) async {
    final query = await _firestore
        .collection('pins')
        .where('tripId', isEqualTo: tripId)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }
}
