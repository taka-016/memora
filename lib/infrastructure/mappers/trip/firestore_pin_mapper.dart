import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/pin.dart';

class FirestorePinMapper {
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
