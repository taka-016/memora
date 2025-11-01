import 'package:equatable/equatable.dart';

class RouteLocation extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String? name;

  const RouteLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
  });

  @override
  List<Object?> get props => [id, latitude, longitude, name];
}
