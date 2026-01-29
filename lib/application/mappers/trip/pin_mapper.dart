import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/domain/entities/trip/pin.dart';

class PinMapper {
  static PinDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PinDto(
      pinId: data?['pinId'] as String? ?? '',
      tripId: data?['tripId'] as String?,
      groupId: data?['groupId'] as String?,
      latitude: data?['latitude'] as double? ?? 0.0,
      longitude: data?['longitude'] as double? ?? 0.0,
      locationName: data?['locationName'] as String?,
      visitStartDate: (data?['visitStartDate'] as Timestamp?)?.toDate(),
      visitEndDate: (data?['visitEndDate'] as Timestamp?)?.toDate(),
      visitMemo: data?['visitMemo'] as String?,
    );
  }

  static Pin toEntity(PinDto dto) {
    return Pin(
      pinId: dto.pinId,
      tripId: dto.tripId ?? '',
      groupId: dto.groupId ?? '',
      latitude: dto.latitude,
      longitude: dto.longitude,
      locationName: dto.locationName,
      visitStartDate: dto.visitStartDate,
      visitEndDate: dto.visitEndDate,
      visitMemo: dto.visitMemo,
    );
  }

  static List<Pin> toEntityList(List<PinDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
