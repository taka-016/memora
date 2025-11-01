import 'package:equatable/equatable.dart';

class RouteLeg extends Equatable {
  final String? localizedDistanceText;
  final String? localizedDurationText;
  final String? primaryInstruction;

  const RouteLeg({
    this.localizedDistanceText,
    this.localizedDurationText,
    this.primaryInstruction,
  });

  @override
  List<Object?> get props => [
    localizedDistanceText,
    localizedDurationText,
    primaryInstruction,
  ];
}
