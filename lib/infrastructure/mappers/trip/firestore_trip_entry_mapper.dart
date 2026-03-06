import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class FirestoreTripEntryMapper {
  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<PinDto> pins = const [],
    List<TaskDto> tasks = const [],
  }) {
    final data = doc.data() ?? {};
    final tripStartTimestamp = data['tripStartDate'] as Timestamp?;
    final tripEndTimestamp = data['tripEndDate'] as Timestamp?;
    final tripStartDate = tripStartTimestamp?.toDate();
    final tripEndDate = tripEndTimestamp?.toDate();
    return TripEntryDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      tripYear:
          data['tripYear'] as int? ??
          tripStartDate?.year ??
          DateTime.now().year,
      tripName: data['tripName'] as String?,
      tripStartDate: tripStartDate,
      tripEndDate: tripEndDate,
      tripMemo: data['tripMemo'] as String?,
      pins: pins,
      tasks: tasks,
    );
  }

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
