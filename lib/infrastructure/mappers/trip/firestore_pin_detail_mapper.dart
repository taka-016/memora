import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/pin_detail.dart';

class FirestorePinDetailMapper {
  static PinDetail fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PinDetail(
      pinId: data?['pinId'] as String? ?? '',
      name: data?['name'] as String?,
      startDate: data?['startDate'] != null
          ? (data!['startDate'] as Timestamp).toDate()
          : null,
      endDate: data?['endDate'] != null
          ? (data!['endDate'] as Timestamp).toDate()
          : null,
      memo: data?['memo'] as String?,
    );
  }

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
