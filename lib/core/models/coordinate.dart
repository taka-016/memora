import 'package:equatable/equatable.dart';

class Coordinate extends Equatable {
  const Coordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];
}
