import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreTripEntryMapper {
  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required int fallbackTripYear,
    List<PinDto> pins = const [],
    List<TaskDto> tasks = const [],
  }) {
    final data = doc.data() ?? {};
    final tripStartDate = FirestoreMapperValueParser.asDateTime(
      data['startDate'],
    );
    final tripEndDate = FirestoreMapperValueParser.asDateTime(data['endDate']);
    final tripYear = FirestoreMapperValueParser.asNullableInt(data['year']);
    return TripEntryDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      tripYear: tripYear ?? tripStartDate?.year ?? fallbackTripYear,
      tripName: data['name'] as String?,
      tripStartDate: tripStartDate,
      tripEndDate: tripEndDate,
      tripMemo: data['memo'] as String?,
      pins: pins,
      tasks: tasks,
    );
  }

  static Map<String, dynamic> toCreateFirestore(TripEntry tripEntry) {
    final data = <String, dynamic>{
      'groupId': tripEntry.groupId,
      'year': tripEntry.tripYear,
      'name': tripEntry.tripName,
      'memo': tripEntry.tripMemo,
      ...FirestoreWriteMetadata.forCreate(),
    };

    data['startDate'] = tripEntry.tripStartDate != null
        ? Timestamp.fromDate(tripEntry.tripStartDate!)
        : null;
    data['endDate'] = tripEntry.tripEndDate != null
        ? Timestamp.fromDate(tripEntry.tripEndDate!)
        : null;

    return data;
  }

  static Map<String, dynamic> toUpdateFirestore(TripEntry tripEntry) {
    final data = <String, dynamic>{
      'groupId': tripEntry.groupId,
      'year': tripEntry.tripYear,
      'name': tripEntry.tripName,
      'memo': tripEntry.tripMemo,
      ...FirestoreWriteMetadata.forUpdate(),
    };

    data['startDate'] = tripEntry.tripStartDate != null
        ? Timestamp.fromDate(tripEntry.tripStartDate!)
        : null;
    data['endDate'] = tripEntry.tripEndDate != null
        ? Timestamp.fromDate(tripEntry.tripEndDate!)
        : null;

    return data;
  }
}
