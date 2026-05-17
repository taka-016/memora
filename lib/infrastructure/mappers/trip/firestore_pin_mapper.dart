import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/entities/trip/pin.dart';
import 'package:memora/infrastructure/mappers/firestore_mapper_value_parser.dart';
import 'package:memora/infrastructure/mappers/firestore_write_metadata.dart';

class FirestorePinMapper {
  static PinDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PinDto(
      pinId: data['pinId'] as String? ?? '',
      tripId: data['tripId'] as String?,
      groupId: data['groupId'] as String?,
      latitude: FirestoreMapperValueParser.asDouble(data['latitude']),
      longitude: FirestoreMapperValueParser.asDouble(data['longitude']),
      locationName: data['locationName'] as String?,
      visitStartDate: FirestoreMapperValueParser.asDateTime(
        data['visitStartDateTime'],
      ),
      visitEndDate: FirestoreMapperValueParser.asDateTime(
        data['visitEndDateTime'],
      ),
      visitMemo: data['memo'] as String?,
    );
  }

  static Map<String, dynamic> toCreateFirestore(Pin pin) {
    return {
      'pinId': pin.pinId,
      'tripId': pin.tripId,
      'groupId': pin.groupId,
      'latitude': pin.latitude,
      'longitude': pin.longitude,
      'locationName': pin.locationName,
      'visitStartDateTime': pin.visitStartDate != null
          ? Timestamp.fromDate(pin.visitStartDate!)
          : null,
      'visitEndDateTime': pin.visitEndDate != null
          ? Timestamp.fromDate(pin.visitEndDate!)
          : null,
      'memo': pin.visitMemo,
      ...FirestoreWriteMetadata.forCreate(),
    };
  }
}
