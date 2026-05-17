import 'package:equatable/equatable.dart';
import 'package:memora/domain/exceptions/validation_exception.dart';

class Pin extends Equatable {
  Pin({
    required this.pinId,
    required this.tripId,
    required this.groupId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.visitStartDateTime,
    this.visitEndDateTime,
    this.memo,
  }) {
    final start = visitStartDateTime;
    final end = visitEndDateTime;
    if (start != null && end != null && end.isBefore(start)) {
      throw ValidationException('訪問終了日時は訪問開始日時以降でなければなりません');
    }
  }

  final String pinId;
  final String tripId;
  final String groupId;
  final double latitude;
  final double longitude;
  final String? locationName;
  final DateTime? visitStartDateTime;
  final DateTime? visitEndDateTime;
  final String? memo;

  Pin copyWith({
    String? pinId,
    String? tripId,
    String? groupId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? visitStartDateTime,
    DateTime? visitEndDateTime,
    String? memo,
  }) {
    return Pin(
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      groupId: groupId ?? this.groupId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      visitStartDateTime: visitStartDateTime ?? this.visitStartDateTime,
      visitEndDateTime: visitEndDateTime ?? this.visitEndDateTime,
      memo: memo ?? this.memo,
    );
  }

  @override
  List<Object?> get props => [
    pinId,
    tripId,
    groupId,
    latitude,
    longitude,
    locationName,
    visitStartDateTime,
    visitEndDateTime,
    memo,
  ];
}
