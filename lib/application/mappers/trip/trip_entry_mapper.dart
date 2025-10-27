import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class TripEntryMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<PinDto> pins = const [],
  }) {
    final data = doc.data() ?? {};
    return TripEntryDto(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      tripName: data['tripName'] as String?,
      tripStartDate:
          (data['tripStartDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      tripEndDate:
          (data['tripEndDate'] as Timestamp?)?.toDate() ?? _defaultDate,
      tripMemo: data['tripMemo'] as String?,
      pins: pins,
    );
  }

  static TripEntry toEntity(TripEntryDto dto) {
    final pinDtos = dto.pins ?? const <PinDto>[];
    return TripEntry(
      id: dto.id,
      groupId: dto.groupId,
      tripName: dto.tripName,
      tripStartDate: dto.tripStartDate,
      tripEndDate: dto.tripEndDate,
      tripMemo: dto.tripMemo,
      pins: PinMapper.toEntityList(pinDtos),
    );
  }

  static TripEntryDto toDto(TripEntry entity) {
    return TripEntryDto(
      id: entity.id,
      groupId: entity.groupId,
      tripName: entity.tripName,
      tripStartDate: entity.tripStartDate,
      tripEndDate: entity.tripEndDate,
      tripMemo: entity.tripMemo,
      pins: PinMapper.toDtoList(entity.pins),
    );
  }

  static List<TripEntry> toEntityList(List<TripEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static List<TripEntryDto> toDtoList(List<TripEntry> entities) {
    return entities.map(toDto).toList();
  }
}
