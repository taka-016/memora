import 'package:equatable/equatable.dart';

class TripParticipant extends Equatable {
  const TripParticipant({
    required this.id,
    required this.tripId,
    required this.memberId,
  });

  final String id;
  final String tripId;
  final String memberId;

  TripParticipant copyWith({String? id, String? tripId, String? memberId}) {
    return TripParticipant(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      memberId: memberId ?? this.memberId,
    );
  }

  @override
  List<Object?> get props => [id, tripId, memberId];
}
