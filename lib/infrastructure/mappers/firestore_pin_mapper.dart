import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_verification/domain/entities/pin.dart';

class FirestorePinMapper {
  static Pin fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Pin(
      id: doc.id,
      markerId: data?['markerId'] as String? ?? '',
      latitude: (data?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data?['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
