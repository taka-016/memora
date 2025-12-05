import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/application/dtos/trip/trip_entry_dto.dart';
import 'package:memora/application/mappers/trip/pin_mapper.dart';
import 'package:memora/application/mappers/trip/route_mapper.dart';
import 'package:memora/domain/entities/trip/trip_entry.dart';

class TripEntryMapper {
  static final _defaultDate = DateTime.fromMillisecondsSinceEpoch(0);

  static TripEntryDto fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    List<PinDto> pins = const [],
    List<RouteDto> routes = const [],
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
      routes: routes,
    );
  }

  static TripEntry toEntity(TripEntryDto dto) {
    final pinDtos = dto.pins ?? const <PinDto>[];
    final routeDtos = dto.routes ?? const <RouteDto>[];
    return TripEntry(
      id: dto.id,
      groupId: dto.groupId,
      tripName: dto.tripName,
      tripStartDate: dto.tripStartDate,
      tripEndDate: dto.tripEndDate,
      tripMemo: dto.tripMemo,
      pins: PinMapper.toEntityList(pinDtos),
      routes: RouteMapper.toEntityList(routeDtos),
    );
  }

  static List<TripEntry> toEntityList(List<TripEntryDto> dtos) {
    return dtos.map(toEntity).toList();
  }
}
