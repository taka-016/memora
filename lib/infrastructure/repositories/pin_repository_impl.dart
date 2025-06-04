import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/entities/pin.dart';
import '../mappers/pin_mapper.dart';

class PinRepositoryImpl implements PinRepository {
  final FirebaseFirestore _firestore;

  PinRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> savePin(
    String markerId,
    double latitude,
    double longitude,
  ) async {
    await _firestore.collection('pins').add({
      'markerId': markerId,
      'latitude': latitude,
      'longitude': longitude,
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
  Future<void> deletePin(String markerId) async {
    final query = await _firestore
        .collection('pins')
        .where('markerId', isEqualTo: markerId)
        .get();
    for (final doc in query.docs) {
      await _firestore.collection('pins').doc(doc.id).delete();
    }
  }
}
