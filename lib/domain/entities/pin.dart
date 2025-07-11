import 'package:equatable/equatable.dart';

class Pin extends Equatable {
  const Pin({
    required this.id,
    required this.pinId,
    this.tripId,
    required this.latitude,
    required this.longitude,
    this.visitStartDate,
    this.visitEndDate,
    this.visitMemo,
  });

  final String id;
  final String pinId;
  final String? tripId;
  final double latitude;
  final double longitude;
  final DateTime? visitStartDate;
  final DateTime? visitEndDate;
  final String? visitMemo;

  Pin copyWith({
    String? id,
    String? pinId,
    String? tripId,
    double? latitude,
    double? longitude,
    DateTime? visitStartDate,
    DateTime? visitEndDate,
    String? visitMemo,
  }) {
    return Pin(
      id: id ?? this.id,
      pinId: pinId ?? this.pinId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      visitStartDate: visitStartDate ?? this.visitStartDate,
      visitEndDate: visitEndDate ?? this.visitEndDate,
      visitMemo: visitMemo ?? this.visitMemo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    pinId,
    tripId,
    latitude,
    longitude,
    visitStartDate,
    visitEndDate,
    visitMemo,
  ];
}
