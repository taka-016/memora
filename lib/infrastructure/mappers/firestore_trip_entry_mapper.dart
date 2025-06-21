import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip_entry.dart';

class FirestoreTripEntryMapper {
  static TripEntry fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TripEntry(
      id: doc.id,
      groupId: data?['groupId'] as String? ?? '',
      tripName: data?['tripName'] as String?,
      tripStartDate:
          (data?['tripStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripEndDate:
          (data?['tripEndDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tripMemo: data?['tripMemo'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(TripEntry tripEntry) {
    return {
      'groupId': tripEntry.groupId,
      'tripName': tripEntry.tripName,
      'tripStartDate': Timestamp.fromDate(tripEntry.tripStartDate),
      'tripEndDate': Timestamp.fromDate(tripEntry.tripEndDate),
      'tripMemo': tripEntry.tripMemo,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
