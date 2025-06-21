import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip_participant.dart';

class FirestoreTripParticipantMapper {
  static TripParticipant fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TripParticipant(
      id: doc.id,
      tripId: data?['tripId'] as String? ?? '',
      memberId: data?['memberId'] as String? ?? '',
    );
  }

  static Map<String, dynamic> toFirestore(TripParticipant tripParticipant) {
    return {
      'tripId': tripParticipant.tripId,
      'memberId': tripParticipant.memberId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
