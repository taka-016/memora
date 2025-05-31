import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
}
