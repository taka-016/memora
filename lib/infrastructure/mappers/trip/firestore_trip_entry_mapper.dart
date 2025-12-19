import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class FirestoreTripEntryMapper {
  static Map<String, dynamic> toFirestore(TripEntry tripEntry) {
    final data = <String, dynamic>{
      'groupId': tripEntry.groupId,
      'tripYear': tripEntry.tripYear,
      'tripName': tripEntry.tripName,
      'tripMemo': tripEntry.tripMemo,
      'createdAt': FieldValue.serverTimestamp(),
    };

    data['tripStartDate'] = tripEntry.tripStartDate != null
        ? Timestamp.fromDate(tripEntry.tripStartDate!)
        : null;
    data['tripEndDate'] = tripEntry.tripEndDate != null
        ? Timestamp.fromDate(tripEntry.tripEndDate!)
        : null;

    return data;
  }
}
