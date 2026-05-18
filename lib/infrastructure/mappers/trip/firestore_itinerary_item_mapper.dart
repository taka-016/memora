import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/itinerary_item_dto.dart';
import 'package:memora/domain/entities/trip/itinerary_item.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestoreItineraryItemMapper {
  static ItineraryItemDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ItineraryItemDto(
      id: doc.id,
      tripId: data['tripId'] as String? ?? '',
      orderIndex: FirestoreMapperValueParser.asInt(data['orderIndex']),
      name: data['name'] as String? ?? '',
      startDateTime: FirestoreMapperValueParser.asDateTime(
        data['startDateTime'],
      ),
      endDateTime: FirestoreMapperValueParser.asDateTime(data['endDateTime']),
      memo: data['memo'] as String?,
    );
  }

  static Map<String, dynamic> toCreateFirestore(ItineraryItem item) {
    final data = <String, dynamic>{
      'tripId': item.tripId,
      'orderIndex': item.orderIndex,
      'name': item.name,
      'memo': item.memo,
      ...FirestoreWriteMetadata.forCreate(),
    };

    data['startDateTime'] = item.startDateTime != null
        ? Timestamp.fromDate(item.startDateTime!)
        : null;
    data['endDateTime'] = item.endDateTime != null
        ? Timestamp.fromDate(item.endDateTime!)
        : null;

    return data;
  }
}
