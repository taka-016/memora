import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/trip_participant_repository.dart';
import '../../domain/entities/trip_participant.dart';
import '../mappers/firestore_trip_participant_mapper.dart';
import '../../core/app_logger.dart';

class FirestoreTripParticipantRepository implements TripParticipantRepository {
  final FirebaseFirestore _firestore;

  FirestoreTripParticipantRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveTripParticipant(TripParticipant tripParticipant) async {
    await _firestore
        .collection('trip_participants')
        .add(FirestoreTripParticipantMapper.toFirestore(tripParticipant));
  }

  @override
  Future<List<TripParticipant>> getTripParticipants() async {
    try {
      final snapshot = await _firestore.collection('trip_participants').get();
      return snapshot.docs
          .map((doc) => FirestoreTripParticipantMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripParticipantRepository.getTripParticipants: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deleteTripParticipant(String tripParticipantId) async {
    await _firestore
        .collection('trip_participants')
        .doc(tripParticipantId)
        .delete();
  }

  @override
  Future<List<TripParticipant>> getTripParticipantsByTripId(
    String tripId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('trip_participants')
          .where('tripId', isEqualTo: tripId)
          .get();
      return snapshot.docs
          .map((doc) => FirestoreTripParticipantMapper.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      logger.e(
        'FirestoreTripParticipantRepository.getTripParticipantsByTripId: ${e.toString()}',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  @override
  Future<void> deleteTripParticipantsByMemberId(String memberId) async {
    final snapshot = await _firestore
        .collection('trip_participants')
        .where('memberId', isEqualTo: memberId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<void> deleteTripParticipantsByTripId(String tripId) async {
    final snapshot = await _firestore
        .collection('trip_participants')
        .where('tripId', isEqualTo: tripId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
