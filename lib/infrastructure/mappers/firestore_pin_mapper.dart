import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/pin.dart';

class FirestorePinMapper {
  static Pin fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Pin(
      id: doc.id,
      pinId: data?['pinId'] as String? ?? '',
      tripId: data?['tripId'] as String? ?? '',
      groupId: data?['groupId'] as String? ?? '',
      latitude: (data?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data?['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: data?['locationName'] as String?,
      visitStartDate: data?['visitStartDate'] != null
          ? (data!['visitStartDate'] as Timestamp).toDate()
          : null,
      visitEndDate: data?['visitEndDate'] != null
          ? (data!['visitEndDate'] as Timestamp).toDate()
          : null,
      visitMemo: data?['visitMemo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Pin pin) {
    return {
      'pinId': pin.pinId,
      'tripId': pin.tripId,
      'groupId': pin.groupId,
      'latitude': pin.latitude,
      'longitude': pin.longitude,
      'locationName': pin.locationName,
      'visitStartDate': pin.visitStartDate != null
          ? Timestamp.fromDate(pin.visitStartDate!)
          : null,
      'visitEndDate': pin.visitEndDate != null
          ? Timestamp.fromDate(pin.visitEndDate!)
          : null,
      'visitMemo': pin.visitMemo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
