import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/mappers/firestore_trip_participant_mapper.dart';
import 'package:memora/domain/entities/trip_participant.dart';
import '../repositories/firestore_trip_participant_repository_test.mocks.dart';

void main() {
  group('FirestoreTripParticipantMapper', () {
    test('FirestoreのDocumentSnapshotからTripParticipantへ変換できる', () {
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('participant001');
      when(
        mockDoc.data(),
      ).thenReturn({'tripId': 'trip001', 'memberId': 'member001'});

      final tripParticipant = FirestoreTripParticipantMapper.fromFirestore(
        mockDoc,
      );

      expect(tripParticipant.id, 'participant001');
      expect(tripParticipant.tripId, 'trip001');
      expect(tripParticipant.memberId, 'member001');
    });

    test('TripParticipantからFirestoreのMapへ変換できる', () {
      final tripParticipant = TripParticipant(
        id: 'participant001',
        tripId: 'trip001',
        memberId: 'member001',
      );

      final data = FirestoreTripParticipantMapper.toFirestore(tripParticipant);

      expect(data['tripId'], 'trip001');
      expect(data['memberId'], 'member001');
      expect(data['createdAt'], isA<FieldValue>());
    });
  });
}
