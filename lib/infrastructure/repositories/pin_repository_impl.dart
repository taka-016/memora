import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/entities/pin.dart';
import '../mappers/pin_mapper.dart';

class PinRepositoryImpl implements PinRepository {
  final FirebaseFirestore _firestore;

  PinRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> savePin(LatLng position) async {
    await _firestore.collection('pins').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<Pin>> getPins() async {
    try {
      final snapshot = await _firestore.collection('pins').get();
      return snapshot.docs.map((doc) => PinMapper.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deletePin(double latitude, double longitude) async {
    final query = await _firestore
        .collection('pins')
        .where('latitude', isEqualTo: latitude)
        .where('longitude', isEqualTo: longitude)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }
}
