import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/pin.dart';
import '../mappers/pin_mapper.dart';

class PinRepository {
  final FirebaseFirestore _firestore;

  PinRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ピン位置を保存
  Future<void> savePin(LatLng position) async {
    await _firestore.collection('pins').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ピン位置リストを取得
  Future<List<Pin>> getPins() async {
    try {
      final snapshot = await _firestore.collection('pins').get();
      return snapshot.docs.map((doc) => PinMapper.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
