import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';
import 'package:memora/core/enums/travel_mode.dart';
import 'package:memora/domain/entities/trip/route.dart' as entity;

class RouteMapper {
  static RouteDto fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RouteDto(
      id: doc.id,
      tripId: data['tripId'] as String? ?? '',
      orderIndex: _asInt(data['orderIndex']),
      departurePinId: data['departurePinId'] as String? ?? '',
      arrivalPinId: data['arrivalPinId'] as String? ?? '',
      travelMode: _travelModeFromString(data['travelMode'] as String?),
      distanceMeters: _asNullableInt(data['distanceMeters']),
      durationSeconds: _asNullableInt(data['durationSeconds']),
      instructions: data['instructions'] as String?,
      polyline: data['polyline'] as String?,
    );
  }

  static entity.Route toEntity(RouteDto dto) {
    return entity.Route(
      tripId: dto.tripId,
      orderIndex: dto.orderIndex,
      departurePinId: dto.departurePinId,
      arrivalPinId: dto.arrivalPinId,
      travelMode: dto.travelMode,
      distanceMeters: dto.distanceMeters,
      durationSeconds: dto.durationSeconds,
      instructions: dto.instructions,
      polyline: dto.polyline,
    );
  }

  static List<entity.Route> toEntityList(List<RouteDto> dtos) {
    return dtos.map(toEntity).toList();
  }

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  static int? _asNullableInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static TravelMode _travelModeFromString(String? value) {
    if (value == null || value.isEmpty) {
      return TravelMode.other;
    }
    final upper = value.toUpperCase();
    return TravelMode.values.firstWhere(
      (mode) => mode.apiValue == upper,
      orElse: () => TravelMode.other,
    );
  }
}
