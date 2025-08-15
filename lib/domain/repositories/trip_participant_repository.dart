import 'package:memora/domain/entities/trip_participant.dart';

abstract class TripParticipantRepository {
  Future<List<TripParticipant>> getTripParticipants();
  Future<void> saveTripParticipant(TripParticipant tripParticipant);
  Future<void> deleteTripParticipant(String tripParticipantId);
  Future<List<TripParticipant>> getTripParticipantsByTripId(String tripId);
  Future<void> deleteTripParticipantsByMemberId(String memberId);
  Future<void> deleteTripParticipantsByTripId(String tripId);
}
