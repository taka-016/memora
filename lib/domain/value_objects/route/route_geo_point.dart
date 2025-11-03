import 'package:equatable/equatable.dart';

class RouteGeoPoint extends Equatable {
  final double latitude;
  final double longitude;

  const RouteGeoPoint({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
