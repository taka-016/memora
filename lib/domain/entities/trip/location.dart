import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Location extends Equatable {
  Location({
    required this.id,
    required this.tripId,
    required this.groupId,
    required this.latitude,
    required this.longitude,
    this.name,
  }) {
    _validate();
  }

  final String id;
  final String tripId;
  final String groupId;
  final String? name;
  final double latitude;
  final double longitude;

  Location copyWith({
    String? id,
    String? tripId,
    String? groupId,
    Object? name = _copyWithPlaceholder,
    double? latitude,
    double? longitude,
  }) {
    return Location(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      name: identical(name, _copyWithPlaceholder) ? this.name : name as String?,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  void _validate() {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw ValidationException('緯度と経度は有効な数値でなければなりません');
    }
  }

  @override
  List<Object?> get props => [id, tripId, groupId, name, latitude, longitude];
}

const Object _copyWithPlaceholder = Object();
