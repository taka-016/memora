import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';

class FirestorePinDetailMapper {
  static Map<String, dynamic> toFirestore(PinDetail pinDetail) {
    return {
      'pinId': pinDetail.pinId,
      'name': pinDetail.name,
      'startDate': pinDetail.startDate != null
          ? Timestamp.fromDate(pinDetail.startDate!)
          : null,
      'endDate': pinDetail.endDate != null
          ? Timestamp.fromDate(pinDetail.endDate!)
          : null,
      'memo': pinDetail.memo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
