import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/domain/entities/member_invitation.dart';
import 'package:memora/infrastructure/services/query_services/firestore_member_invitation_query_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_exception.dart';
import 'firestore_member_invitation_query_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  group('FirestoreMemberInvitationQueryService', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockInvitationCollection;
    late FirestoreMemberInvitationQueryService service;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockInvitationCollection =
          MockCollectionReference<Map<String, dynamic>>();
      when(
        mockFirestore.collection('member_invitations'),
      ).thenReturn(mockInvitationCollection);
      service = FirestoreMemberInvitationQueryService(firestore: mockFirestore);
    });

    test('inviteeIdで招待情報を取得する', () async {
      const inviteeId = 'invitee001';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockInvitationCollection.where('inviteeId', isEqualTo: inviteeId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('invitation123');
      when(mockDoc.data()).thenReturn({
        'inviteeId': inviteeId,
        'inviterId': 'inviter001',
        'invitationCode': 'CODE123',
      });

      final result = await service.getByInviteeId(inviteeId);

      expect(result, isNotNull);
      expect(result, isA<MemberInvitation>());
      expect(result!.invitationCode, 'CODE123');
    });

    test('inviteeIdで該当なしの場合はnullを返す', () async {
      const inviteeId = 'invitee404';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockInvitationCollection.where('inviteeId', isEqualTo: inviteeId),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final result = await service.getByInviteeId(inviteeId);

      expect(result, isNull);
    });

    test('inviteeId取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockInvitationCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getByInviteeId('invitee001');

      expect(result, isNull);
    });

    test('招待コードで招待情報を取得する', () async {
      const invitationCode = 'CODE999';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      final mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      when(
        mockInvitationCollection.where(
          'invitationCode',
          isEqualTo: invitationCode,
        ),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.id).thenReturn('invitation789');
      when(mockDoc.data()).thenReturn({
        'inviteeId': 'invitee777',
        'inviterId': 'inviter888',
        'invitationCode': invitationCode,
      });

      final result = await service.getByInvitationCode(invitationCode);

      expect(result, isNotNull);
      expect(result!.inviterId, 'inviter888');
    });

    test('招待コードで該当なしの場合はnullを返す', () async {
      const invitationCode = 'CODE000';
      final mockQuery = MockQuery<Map<String, dynamic>>();
      final mockSnapshot = MockQuerySnapshot<Map<String, dynamic>>();

      when(
        mockInvitationCollection.where(
          'invitationCode',
          isEqualTo: invitationCode,
        ),
      ).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(mockSnapshot.docs).thenReturn([]);

      final result = await service.getByInvitationCode(invitationCode);

      expect(result, isNull);
    });

    test('招待コード取得時に例外が発生した場合はnullを返す', () async {
      when(
        mockInvitationCollection.where(any, isEqualTo: anyNamed('isEqualTo')),
      ).thenThrow(TestException('Firestore error'));

      final result = await service.getByInvitationCode('CODE123');

      expect(result, isNull);
    });
  });
}
