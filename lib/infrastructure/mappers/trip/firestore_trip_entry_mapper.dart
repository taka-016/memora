import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class FirestoreTripEntryMapper {
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
