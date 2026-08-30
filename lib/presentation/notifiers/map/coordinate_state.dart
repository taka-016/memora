import 'package:equatable/equatable.dart';
import 'package:memora/core/models/coordinate.dart';

class CoordinateState extends Equatable {
  final Coordinate? coordinate;
  final DateTime? lastUpdated;

  const CoordinateState({this.coordinate, this.lastUpdated});

  CoordinateState copyWith({Coordinate? coordinate, DateTime? lastUpdated}) {
    return CoordinateState(
      coordinate: coordinate ?? this.coordinate,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [coordinate, lastUpdated];
}
