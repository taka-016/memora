import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memora/infrastructure/repositories/firestore_trip_participant_repository.dart';
import 'package:memora/domain/entities/trip_participant.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
])
import 'firestore_trip_participant_repository_test.mocks.dart';

void main() {
  group('FirestoreTripParticipantRepository', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late FirestoreTripParticipantRepository repository;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc1;
    late MockQuery<Map<String, dynamic>> mockQuery;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      mockQuery = MockQuery<Map<String, dynamic>>();
      when(mockFirestore.collection('trip_participants')).thenReturn(mockCollection);
      repository = FirestoreTripParticipantRepository(firestore: mockFirestore);
    });

    test('saveTripParticipantがtrip_participants collectionに参加者情報をaddする', () async {
      final tripParticipant = TripParticipant(
        id: 'participant001',
        tripId: 'trip001',
        memberId: 'member001',
      );

      when(
        mockCollection.add(any),
      ).thenAnswer((_) async => MockDocumentReference<Map<String, dynamic>>());

      await repository.saveTripParticipant(tripParticipant);

      verify(
        mockCollection.add(
          argThat(
            allOf([
              containsPair('tripId', 'trip001'),
              containsPair('memberId', 'member001'),
              contains('createdAt'),
            ]),
          ),
        ),
      ).called(1);
    });

    test('getTripParticipantsがFirestoreからTripParticipantのリストを返す', () async {
      when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('participant001');
      when(mockDoc1.data()).thenReturn({
        'tripId': 'trip001',
        'memberId': 'member001',
      });

      final result = await repository.getTripParticipants();

      expect(result.length, 1);
      expect(result[0].id, 'participant001');
      expect(result[0].tripId, 'trip001');
      expect(result[0].memberId, 'member001');
    });

    test('getTripParticipantsがエラー時に空のリストを返す', () async {
      when(mockCollection.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getTripParticipants();

      expect(result, isEmpty);
    });

    test('deleteTripParticipantがtrip_participants collectionの該当ドキュメントを削除する', () async {
      const participantId = 'participant001';
      final mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      when(mockCollection.doc(participantId)).thenReturn(mockDocRef);
      when(mockDocRef.delete()).thenAnswer((_) async {});

      await repository.deleteTripParticipant(participantId);

      verify(mockCollection.doc(participantId)).called(1);
      verify(mockDocRef.delete()).called(1);
    });

    test('getTripParticipantsByTripIdが特定の旅行の参加者リストを返す', () async {
      const tripId = 'trip001';

      when(mockCollection.where('tripId', isEqualTo: tripId)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
      when(mockDoc1.id).thenReturn('participant001');
      when(mockDoc1.data()).thenReturn({
        'tripId': tripId,
        'memberId': 'member001',
      });

      final result = await repository.getTripParticipantsByTripId(tripId);

      expect(result.length, 1);
      expect(result[0].id, 'participant001');
      expect(result[0].tripId, tripId);
      expect(result[0].memberId, 'member001');
    });

    test('getTripParticipantsByTripIdがエラー時に空のリストを返す', () async {
      const tripId = 'trip001';

      when(mockCollection.where('tripId', isEqualTo: tripId)).thenReturn(mockQuery);
      when(mockQuery.get()).thenThrow(Exception('Firestore error'));

      final result = await repository.getTripParticipantsByTripId(tripId);

      expect(result, isEmpty);
    });
  });
}