import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/application/dtos/trip/task_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreTripEntryMapper {
  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required int fallbackTripYear,
    List<TaskDto> tasks = const [],
    List<ItineraryItemDto> itineraryItems = const [],
  }) {
    final data = doc.data() ?? {};
    final startDate = FirestoreMapperValueParser.asDateTime(data['startDate']);
    final endDate = FirestoreMapperValueParser.asDateTime(data['endDate']);
    final year = FirestoreMapperValueParser.asNullableInt(data['year']);
    return TripEntryDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      year: year ?? startDate?.year ?? fallbackTripYear,
      name: data['name'] as String?,
      startDate: startDate,
      endDate: endDate,
      memo: data['memo'] as String?,
      tasks: tasks,
      itineraryItems: itineraryItems,
    );
  }

  static Map<String, dynamic> toCreateFirestore(TripEntry tripEntry) {
    final data = <String, dynamic>{
      'groupId': tripEntry.groupId,
      'year': tripEntry.year,
      'name': tripEntry.name,
      'memo': tripEntry.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };

    data['startDate'] = tripEntry.startDate != null
        ? Timestamp.fromDate(tripEntry.startDate!)
        : null;
    data['endDate'] = tripEntry.endDate != null
        ? Timestamp.fromDate(tripEntry.endDate!)
        : null;

    return data;
  }

  static Map<String, dynamic> toUpdateFirestore(TripEntry tripEntry) {
    final data = <String, dynamic>{
      'groupId': tripEntry.groupId,
      'year': tripEntry.year,
      'name': tripEntry.name,
      'memo': tripEntry.memo,
      ...FirestoreWriteMetadata.forUpdate(),
    };

    data['startDate'] = tripEntry.startDate != null
        ? Timestamp.fromDate(tripEntry.startDate!)
        : null;
    data['endDate'] = tripEntry.endDate != null
        ? Timestamp.fromDate(tripEntry.endDate!)
        : null;

    return data;
  }
}
