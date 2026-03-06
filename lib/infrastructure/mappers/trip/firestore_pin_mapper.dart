import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/entities/trip/pin.dart';

class FirestorePinMapper {
  static PinDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PinDto(
      pinId: data?['pinId'] as String? ?? '',
      tripId: data?['tripId'] as String?,
      groupId: data?['groupId'] as String?,
      latitude: _asDouble(data?['latitude']) ?? 0.0,
      longitude: _asDouble(data?['longitude']) ?? 0.0,
      locationName: data?['locationName'] as String?,
      visitStartDate: (data?['visitStartDate'] as Timestamp?)?.toDate(),
      visitEndDate: (data?['visitEndDate'] as Timestamp?)?.toDate(),
      visitMemo: data?['visitMemo'] as String?,
    );
  }

  static double? _asDouble(Object? value) => switch (value) {
    final num number => number.toDouble(),
    _ => null,
  };

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
