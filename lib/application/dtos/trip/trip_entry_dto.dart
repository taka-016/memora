import 'package:equatable/equatable.dart';
import 'package:memora/application/dtos/trip/pin_dto.dart';
import 'package:memora/application/dtos/trip/route_dto.dart';

class TripEntryDto extends Equatable {
  const TripEntryDto({
    required this.id,
    required this.groupId,
    this.tripName,
    required this.tripStartDate,
    required this.tripEndDate,
    this.tripMemo,
    this.pins,
    this.routes,
  });

  final String id;
  final String groupId;
  final String? tripName;
  final DateTime tripStartDate;
  final DateTime tripEndDate;
  final String? tripMemo;
  final List<PinDto>? pins;
  final List<RouteDto>? routes;

  TripEntryDto copyWith({
    String? id,
    String? groupId,
    String? tripName,
    DateTime? tripStartDate,
    DateTime? tripEndDate,
    String? tripMemo,
    List<PinDto>? pins,
    List<RouteDto>? routes,
  }) {
    return TripEntryDto(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tripName: tripName ?? this.tripName,
      tripStartDate: tripStartDate ?? this.tripStartDate,
      tripEndDate: tripEndDate ?? this.tripEndDate,
      tripMemo: tripMemo ?? this.tripMemo,
      pins: pins ?? this.pins,
      routes: routes ?? this.routes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    tripName,
    tripStartDate,
    tripEndDate,
    tripMemo,
    pins,
    routes,
  ];
}
